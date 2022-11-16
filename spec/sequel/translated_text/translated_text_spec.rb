# frozen_string_literal: true

require "sequel/plugins/translated_text"

RSpec.describe SequelTranslatedText, :db do
  before(:all) do
    @db = Suma::Postgres::Model.db
    @db.create_table(:translated_texts, temp: true) do
      primary_key :id
      text :en
      text :fr
    end
    @db.create_table(:articles, temp: true) do
      primary_key :id
      foreign_key :title_id, :translated_texts, null: true
      foreign_key :text_id, :translated_texts, null: true
    end
  end
  after(:all) do
    @db.disconnect
  end

  before(:each) do
    c = Class.new(Sequel::Model(:translated_texts)) do
    end
    stub_const("TranslatedTextEx", c)
  end
  after(:each) do
    SequelTranslatedText.language = nil
  end

  it "has a version" do
    expect(SequelTranslatedText::VERSION).to be_a(String)
  end

  describe "plugin" do
    it "can specify just the model to use to store translated text" do
      cls = Class.new(Sequel::Model(:articles)) do
        plugin :translated_text, :text, TranslatedTextEx
      end
      a = cls.new
      expect(a.text).to be_nil
      a.save_changes
      expect(a.text).to be_a(TranslatedTextEx)
    end

    it "can add the reverse association" do
      cls = Class.new(Sequel::Model(:articles)) do
        plugin :translated_text, :title, TranslatedTextEx, reverse: :article
      end
      a = cls.create
      expect(a).to have_attributes(title: be_a(TranslatedTextEx))
      expect(a.title.article).to be === a
    end

    it "adds a join_translated dataset that joins desired columns" do
      cls = Class.new(Sequel::Model(:articles)) do
        plugin :translated_text, :text, TranslatedTextEx
      end
      x = cls.create(text: TranslatedTextEx.create(en: "x"))
      y = cls.create(text: TranslatedTextEx.create(en: "y"))
      q = cls.dataset.translation_join(:text, [:en, :fr])
      expect(q.sql).to eq('SELECT * FROM (SELECT "articles".*, "text"."en" AS "text_en", "text"."fr" AS "text_fr" ' \
                          'FROM "articles" INNER JOIN "translated_texts" AS "text" ' \
                          'ON ("text"."id" = "articles"."text_id")) AS "t1"')
      expect(q.where(text_en: "x").all).to contain_exactly(be === x)
      expect(q.where(id: -1).all).to be_empty # Ensure we don't get ambiguous columns
    end
  end

  it "can set and reset the language context" do
    cls = Class.new(Sequel::Model(:articles)) do
      plugin :translated_text, :text, TranslatedTextEx
    end
    a = cls.create
    a.text.update(en: "english", fr: "french")

    expect { a.text_string }.to raise_error(SequelTranslatedText::NoContext)

    SequelTranslatedText.language = :en
    expect(a.text.en).to eq("english")
    expect(a.text_string).to eq("english")
    expect(a.text.string).to eq("english")

    SequelTranslatedText.language = :fr
    expect(a.text_string).to eq("french")
    expect(a.text.string).to eq("french")
    a.text_string = "francais"
    expect(a.text_string).to eq("francais")
    expect(a.text.string).to eq("francais")
    expect(a.text.fr).to eq("francais")
    a.text.string = "fancois"
    expect(a.text_string).to eq("fancois")

    SequelTranslatedText.language = nil
    SequelTranslatedText.language(:fr) do
      a.text_string = "french"
      expect(a.text_string).to eq("french")
    end
    expect(SequelTranslatedText.language).to be_nil
  end

  it "uses a thread local context" do
    cls = Class.new(Sequel::Model(:articles)) do
      plugin :translated_text, :text, TranslatedTextEx
    end
    a = cls.create
    a.text.update(en: "english", fr: "french")
    SequelTranslatedText.language = nil
    got = []
    threads = Array.new(4) do |i|
      Thread.new do
        lang = i.even? ? :en : :fr
        SequelTranslatedText.language = lang
        sleep(0)
        got << a.text_string
      end
    end
    threads.each(&:join)
    got.sort!
    expect(got).to eq(["english", "english", "french", "french"])
    expect(SequelTranslatedText.language).to be_nil
  end

  it "can get and set text field via value before it is saved" do
    cls = Class.new(Sequel::Model(:articles)) do
      plugin :translated_text, :text, TranslatedTextEx
    end
    a = cls.new
    SequelTranslatedText.language = :en
    expect(a.text).to be_nil
    expect(a.text_string).to eq("")

    a.text_string = "foo"
    expect(a.text).to be_a(TranslatedTextEx).and(be_saved)
    expect(a.text_string).to eq("foo")
  end

  it "saves the text field when the instance is saved" do
    cls = Class.new(Sequel::Model(:articles)) do
      plugin :translated_text, :text, TranslatedTextEx
    end
    a = cls.new
    SequelTranslatedText.language = :en
    a.text_string = "foo"
    a.save_changes
    expect(a.refresh.text_string).to eq("foo")
    a.text_string = "bar"
    expect(a.refresh.text_string).to eq("foo")
    a.text_string = "bar"
    a.save_changes
    expect(a.refresh.text_string).to eq("bar")
  end

  it "defaults to the default language" do
    cls = Class.new(Sequel::Model(:articles)) do
      plugin :translated_text, :text, TranslatedTextEx
    end
    a = cls.create
    a.text.update(en: "english")

    SequelTranslatedText.default_language = :en
    expect { a.text_string }.to raise_error(SequelTranslatedText::NoContext)

    SequelTranslatedText.language = :fr
    expect(a.text.string).to eq("english")
    SequelTranslatedText.default_language = :fr
    expect(a.text.string).to eq("")
  end

  describe SequelTranslatedText::RackMiddleware do
    let(:env) { Rack::MockRequest.env_for }
    let(:app) do
      lambda do |_env|
        cls = Class.new(Sequel::Model(:articles)) do
          plugin :translated_text, :text, TranslatedTextEx
        end
        a = cls.create
        a.text.update(en: "english", fr: "french")
        [200, {}, a.text_string]
      end
    end

    it "sets the language from the Accept Language header" do
      env["HTTP_ACCEPT_LANGUAGE"] = "da, fr-FR;q=0.8"
      mw = described_class.new(app, languages: [:en, :fr])
      _status, headers, response = mw.call(env)
      expect(headers).to include("Content-Language" => "fr")
      expect(response).to eq("french")
    end

    it "prefers the highest quality match" do
      env["HTTP_ACCEPT_LANGUAGE"] = "en-US;q=0.6, fr-FR;q=0.8"
      mw = described_class.new(app, languages: [:en, :fr])
      _status, headers, response = mw.call(env)
      expect(headers).to include("Content-Language" => "fr")
      expect(response).to eq("french")
    end

    it "uses the default language if no header is present" do
      mw = described_class.new(app, languages: [:en])
      _status, headers, response = mw.call(env)
      expect(headers).to include("Content-Language" => "en")
      expect(response).to eq("english")
    end

    it "uses the default if the given language is unsupported" do
      env["HTTP_ACCEPT_LANGUAGE"] = "de"
      mw = described_class.new(app, languages: [:en, :fr])
      _status, headers, response = mw.call(env)
      expect(headers).to include("Content-Language" => "en")
      expect(response).to eq("english")
    end
  end

  describe "SequelTranslatedText::Model" do
    it "provides an :all param that sets all language columns" do
      c = Class.new(Sequel::Model(:translated_texts)) do
        include SequelTranslatedText::Model
      end
      c = c.create(all: "foo")
      expect(c).to have_attributes(en: "foo", fr: "foo")
    end

    it "can limit the all languages columns if `all_languages` is defined" do
      c = Class.new(Sequel::Model(:translated_texts)) do
        include SequelTranslatedText::Model
        def all_languages
          return [:fr]
        end
      end
      c = c.create(all: "foo")
      expect(c).to have_attributes(en: nil, fr: "foo")
    end
  end
end
