# frozen_string_literal: true

require "suma/i18n"

RSpec.describe Suma::I18n, :db do
  include_context "uses temp dir"

  describe "localized_error_codes" do
    it "returns errors as listed in the strings seed file" do
      expect(described_class.localized_error_codes).to include("auth_conflict")
    end
  end

  describe "import_seeds" do
    it "replaces all static strings in the database" do
      stub_const("Suma::I18n::SEEDS_DIR", temp_dir_path)
      Dir.mkdir(temp_dir_path + "en")
      Dir.mkdir(temp_dir_path + "es")
      File.write(temp_dir_path + "en/ns1.json", {a: {b: "hi", c: "cc"}}.to_json)
      File.write(temp_dir_path + "es/ns1.json", {a: {b: "hola"}}.to_json)
      described_class.import_seeds
      expect(Suma::I18n::StaticString.all).to contain_exactly(
        have_attributes(key: "a.b", namespace: "ns1", text: have_attributes(en: "hi", es: "hola")),
        have_attributes(key: "a.c", namespace: "ns1", text: have_attributes(en: "cc")),
      )
      File.write(temp_dir_path + "en/ns1.json", {a: {b: "bye"}}.to_json)
      described_class.import_seeds
      expect(Suma::I18n::StaticString.all).to contain_exactly(
        have_attributes(key: "a.b", namespace: "ns1", text: have_attributes(en: "bye", es: "hola")),
      )
    end
  end

  describe "export_seeds" do
    it "writes static strings" do
      stub_const("Suma::I18n::SEEDS_DIR", temp_dir_path)

      Suma::Fixtures.static_string.text("hi", es: "hola").create(key: "a.b", namespace: "n1")
      Suma::Fixtures.static_string.text("en1", es: "es1").create(key: "a.c", namespace: "n1")
      Suma::Fixtures.static_string.text("en2", es: "es2").create(key: "a.c", namespace: "n2")

      described_class.export_seeds

      expect(JSON.parse(File.read(temp_dir_path + "en/n1.json"))).to eq({"a.b" => "hi", "a.c" => "en1"})
      expect(JSON.parse(File.read(temp_dir_path + "es/n1.json"))).to eq({"a.b" => "hola", "a.c" => "es1"})
      expect(JSON.parse(File.read(temp_dir_path + "en/n2.json"))).to eq({"a.c" => "en2"})

      expect { described_class.export_seeds }.to_not raise_error
    end
  end

  # nested_hash = {
  #   "x" => 1,
  #   "y" => {
  #     "b" => 1,
  #     "a" => 2,
  #   },
  #   "h" => 3,
  # }
  #
  # before(:each) do
  #   stub_const("Suma::I18n::LOCALE_DIR", temp_dir_path)
  #   stub_const("Suma::Message::DATA_DIR", temp_dir_path)
  #   Dir.mkdir(temp_dir_path + "en")
  #   Dir.mkdir(temp_dir_path + "es")
  # end

  # describe "reformat files" do
  #   it "reformats the files" do
  #     path = described_class.strings_path("en")
  #     File.write(path, '{"x": 1, "y":{"b":1, "a":2}, "h": 3}')
  #     described_class.reformat_files
  #     expect(File.read(path)).to eq(<<~J.rstrip)
  #       {
  #         "h": 3,
  #         "x": 1,
  #         "y": {
  #           "a": 2,
  #           "b": 1
  #         }
  #       }
  #     J
  #   end
  #
  #   it "renders html entities" do
  #     path = described_class.strings_path("en")
  #     File.write(path, '{"x": "«&laquo;&#171;", "y": {"z": "«&laquo;&#171;"}')
  #     described_class.reformat_files
  #     expect(File.read(path)).to eq("{\n  \"x\": \"«««\",\n  \"y\": {\n    \"z\": \"«««\"\n  }\n}")
  #   end
  # end
  #
  # describe "sort_hash" do
  #   it "sorts a nested hash" do
  #     expect(described_class.sort_hash(nested_hash).to_json).to eq('{"h":3,"x":1,"y":{"a":2,"b":1}}')
  #   end
  # end
  #
  describe "flatten_hash" do
    nested_hash = {
      "x" => 1,
      "y" => {
        "b" => 1,
        "a" => 2,
      },
      "h" => 3,
    }

    it "flattens a hash" do
      h = nested_hash.deep_dup
      expect(described_class.flatten_hash(nested_hash)).to eq({"h" => 3, "x" => 1, "y.a" => 2, "y.b" => 1})
      # Assert original unchanged
      expect(nested_hash).to eq(h)
    end
  end
  #
  # describe "prepare_csv" do
  #   it "merges lang-specific data to base data and writes" do
  #     File.write(described_class.strings_path("en"), {hi: "Hi", greeting: {bye: "Bye"}}.to_json)
  #     File.write(described_class.strings_path("es"), {greeting: {bye: "Adiós"}}.to_json)
  #     out = +""
  #     described_class.prepare_csv("es", output: out)
  #     expect(out).to eq("Key,Spanish,English\ngreeting:bye,Adiós,Bye\nhi,,Hi\n")
  #   end
  #
  #   it "renders html entities" do
  #     File.write(described_class.strings_path("en"), {dr: "&lsquo;evil&#8217;"}.to_json)
  #     File.write(described_class.strings_path("es"), {dr: "&lsquo;evil&#8217;"}.to_json)
  #     out = +""
  #     described_class.prepare_csv("es", output: out)
  #     expect(out).to eq("Key,Spanish,English\ndr,‘evil’,‘evil’\n")
  #   end
  #
  #   it "includes messages" do
  #     Dir.mkdir(temp_dir_path + "templates")
  #     Dir.mkdir(temp_dir_path + "templates/subdir")
  #     File.write(temp_dir_path + "templates/tmpl.en.sms.liquid", "english sms 1")
  #     File.write(temp_dir_path + "templates/subdir/tmpl.en.sms.liquid", "english sms 2")
  #     File.write(temp_dir_path + "templates/tmpl.es.sms.liquid", "spanish sms 1")
  #     File.write(temp_dir_path + "templates/subdir/tmpl.es.sms.liquid", "spanish sms 2")
  #     out = +""
  #     described_class.prepare_csv("es", output: out)
  #     expect(out).to eq("Key,Spanish,English\n" \
  #                       "message:/templates/subdir/tmpl.sms,spanish sms 2,english sms 2\n" \
  #                       "message:/templates/tmpl.sms,spanish sms 1,english sms 1\n")
  #   end
  # end
  #
  # describe "import_csv" do
  #   it "applies csv data to stored locale json" do
  #     path = described_class.strings_path("es")
  #     File.write(path, '{"x":1}') # Make sure it gets blown away
  #     csv = "Key,Spanish,English\ngreeting:bye,Adiós,Bye\nhi,,Hi\n"
  #     described_class.import_csv(input: csv)
  #     expect(File.read(path)).to eq(<<~J.rstrip)
  #       {
  #         "greeting": {
  #           "bye": "Adiós"
  #         }
  #       }
  #     J
  #   end
  #
  #   it "ensures interpolation values are unchanged and removes whitespaces" do
  #     path = described_class.strings_path("es")
  #     csv = "Key,Spanish,English\n" \
  #           "food:price_times_quantity,{{ price }} es {{quantity}},{{price}} en {{ quantity }}"
  #     described_class.import_csv(input: csv)
  #     expect(File.read(path)).to eq(<<~J.rstrip)
  #       {
  #         "food": {
  #           "price_times_quantity": "{{price}} es {{quantity}}"
  #         }
  #       }
  #     J
  #   end
  #
  #   it "only stomps dynamic values" do
  #     path = described_class.strings_path("es")
  #     csv = "Key,Spanish,English\n" \
  #           "food:price_times_quantity,{{  price }}  price  es {{ price }},{{ price }}  price  en {{ price }}"
  #     described_class.import_csv(input: csv)
  #     expect(File.read(path)).to eq(<<~J.rstrip)
  #       {
  #         "food": {
  #           "price_times_quantity": "{{price}}  price  es {{price}}"
  #         }
  #       }
  #     J
  #   end
  #
  #   it "errors if interpolation values count do not match" do
  #     csv = "Key,Spanish,English\n" \
  #           "food:price_times_quantity,{{precio}} es,{{price}} en {{ quantity }}"
  #     expect do
  #       described_class.import_csv(input: csv)
  #     end.to raise_error(described_class::InvalidInput, /Dynamic value count should be 2 but is 1:\n{{precio}} es/)
  #   end
  #
  #   it "errors if interpolation values do not match" do
  #     csv = "Key,Spanish,English\n" \
  #           "food:price_times_quantity,{{ precio }} es {{ cantidad }},{{price}} en {{quantity}}"
  #     expect do
  #       described_class.import_csv(input: csv)
  #     end.to raise_error(described_class::InvalidInput, /precio does not match dynamic values: price, quantity/)
  #   end
  #
  #   it "overwrites message templates" do
  #     csv = "Key,Spanish,English\n" \
  #           "message:/templates/subdir/tmpl.sms,spanish sms 2,english sms 2\n" \
  #           "message:/templates/tmpl.sms,spanish sms 1,english sms 1\n"
  #     described_class.import_csv(input: csv)
  #     expect(File.read(Suma::Message::DATA_DIR + "templates/subdir/tmpl.es.sms.liquid").strip).to eq("spanish sms 2")
  #     expect(Pathname(Suma::Message::DATA_DIR + "templates/subdir/tmpl.en.sms.liquid")).to_not exist
  #   end
  # end
  #
  # describe "export_dynamic" do
  #   it "exports all dynamic strings" do
  #     t1 = Suma::Fixtures.translated_text(en: "a1", es: "a2").create
  #     t2 = Suma::Fixtures.translated_text(en: "b1", es: "b2").create
  #     out = +""
  #     described_class.export_dynamic(output: out)
  #     expect(out).to eq("Id,English,Spanish\n#{t1.id},a1,a2\n#{t2.id},b1,b2\n")
  #   end
  # end
  #
  # describe "import_dynamic" do
  #   it "imports dynamic strings" do
  #     t1 = Suma::Fixtures.translated_text(en: "a1", es: "a2").create
  #     t2 = Suma::Fixtures.translated_text(en: "b1", es: "b2").create
  #     inp = "Id,English,Spanish\n#{t1.id},x1,x2\n#{t2.id},y1,y2\n"
  #     described_class.import_dynamic(input: StringIO.new(inp))
  #     expect(Suma::TranslatedText.all).to contain_exactly(
  #       have_attributes(en: "x1", es: "x2"),
  #       have_attributes(en: "y1", es: "y2"),
  #     )
  #   end
  #
  #   it "errors if an id is provided that does not exist" do
  #     t1 = Suma::Fixtures.translated_text(en: "a1", es: "a2").create
  #     inp = "Id,English,Spanish\n#{t1.id},x1,x2\n0,y1,y2\n"
  #     expect do
  #       described_class.import_dynamic(input: StringIO.new(inp))
  #     end.to raise_error(described_class::InvalidInput, /CSV had 2 rows but only matched 1 database rows/)
  #     expect(Suma::TranslatedText.all).to contain_exactly(
  #       have_attributes(en: "a1", es: "a2"),
  #     )
  #   end
  #
  #   it "errors if columns mismatch" do
  #     inp = "Id,English,Spanish,French\n"
  #     expect do
  #       described_class.import_dynamic(input: StringIO.new(inp))
  #     end.to raise_error(described_class::InvalidInput, /Headers should be: Id,English/)
  #   end
  # end
  #
  # describe "convert_source_to_resource_files" do
  #   it "converts all source files" do
  #     src = described_class::LOCALE_DIR + "en/source/foo.md"
  #     dst = described_class::LOCALE_DIR + "en/foo.json"
  #     Dir.mkdir(temp_dir_path + "en/source")
  #     File.write(src, "# title\n\nfirst \"para")
  #     described_class.convert_source_to_resource_files
  #     expect(File.read(dst)).to eq("{\n  \"contents\": \"# title\\n\\nfirst \\\"para\"\n}")
  #   end
  # end
  #
  # describe "rewrite_resource_files" do
  #   it "rewrites resource json to output json" do
  #     src = described_class::LOCALE_DIR + "en/foo.json"
  #     dst = described_class::LOCALE_DIR + "en/out/foo.out.json"
  #     resource_json = {
  #       s1: "S1",
  #       group1: {s2: "S2", g2: {s3: "S3", md1: "**hello**"}},
  #       plain: "fish chips",
  #       amp: "fish & chips",
  #       entity: "fish « chips",
  #       md: "fish **and** chips",
  #     }
  #     File.write(src, resource_json.to_json)
  #     described_class.rewrite_resource_files
  #     expect(File.read(dst)).to include('"s1":["s","S1"]')
  #   end
  # end
  #
  describe "ResourceRewriter" do
    def resfile(ns, h)
      return described_class::ResourceRewriter::ResourceFile.new(h.deep_stringify_keys, namespace: ns)
    end

    def rewrite(s)
      rr = described_class::ResourceRewriter.new
      rf = resfile("strings", {s:})
      rr.prime(rf)
      return rr.to_output(rf).fetch("s")
    end

    it "writes simple strings" do
      expect(rewrite("abc d")).to eq([:s, "abc d"])
      expect(rewrite("a")).to eq([:s, "a"])
    end

    it "trims spaces" do
      expect(rewrite("")).to eq([:s, ""])
      expect(rewrite(" ")).to eq([:s, ""])
      expect(rewrite(" a ")).to eq([:s, "a"])
    end

    it "writes markdown strings" do
      expect(rewrite("**x**")).to eq([:m, "**x**"])
      expect(rewrite("a *x* z")).to eq([:m, "a *x* z"])
    end

    it "writes multiline markdown strings" do
      expect(rewrite("x\ny")).to eq([:s, "x\ny"])
      expect(rewrite("x\n\ny")).to eq([:mp, "x\n\ny"])
    end

    it "rewrites interpolated strings" do
      expect(rewrite("{{x}}")).to eq([:s, "@%", {k: "x"}])
      expect(rewrite("{{x.y.z}}")).to eq([:s, "@%", {k: "x.y.z"}])
      expect(rewrite("{{x-2_3.y.z}}")).to eq([:s, "@%", {k: "x-2_3:y.z"}])
      expect(rewrite("{{ x}} y")).to eq([:s, "@% y", {k: "x"}])
      expect(rewrite("{{ x }} *{{y}}*")).to eq([:m, "@% *@%*", {k: "x"}, {k: "y"}])
    end

    it "rewrites interpolated strings with a formatter" do
      expect(rewrite("{{x,currency}}")).to eq([:s, "@%", {f: "currency", k: "x"}])
      expect(rewrite("{{ x, currency}} y")).to eq([:s, "@% y", {f: "currency", k: "x"}])
      expect(rewrite("{{ x, currency }} *{{y,time }}*")).to eq(
        [:m, "@% *@%*", {f: "currency", k: "x"}, {f: "time", k: "y"}],
      )
    end

    it "rewrites strings referencing other strings" do
      expect(rewrite("$t(xy)")).to eq([:s, "@%", {t: "xy"}])
      expect(rewrite("$t(x.y)")).to eq([:s, "@%", {t: "x.y"}])
      expect(rewrite("$t(x-2_3:y:z)")).to eq([:s, "@%", {t: "x-2_3:y:z"}])
      expect(rewrite("a $t(xy) c")).to eq([:s, "a @% c", {t: "xy"}])
      expect(rewrite("a *$t(xy)* $t(c)")).to eq([:m, "a *@%* @%", {t: "xy"}, {t: "c"}])
    end

    it "handles unicode" do
      expect(rewrite("🤣$t(xyz)🤣{{abc}}🤣")).to eq([:s, "🤣@%🤣@%🤣", {t: "xyz"}, {k: "abc"}])
    end

    it "errors if the placeholder is used in a resource string" do
      expect do
        rewrite("hi @%")
      end.to raise_error(described_class::InvalidInput)
    end

    it "errors if the json is not strings and hashes only" do
      expect do
        described_class::ResourceRewriter.new.prime(resfile("test", {s: ["abc"]}))
      end.to raise_error(described_class::InvalidInput)
    end

    it "uses the higher-complexity plain/md/multiline renderer if a reference key uses it" do
      strings = {
        base: "abc",
        md: "a *b* c",
        mdp: "a\n\nb",
        ref_plain: "$t(test.base) $t(test.base)",
        ref_md: "$t(test.base) $t(test.md)",
        ref_mdp: "$t(test.base) $t(test.mdp)",
        ref_mdp_deep: "$t(test.ref_mdp)",
        a: {b: {c: "*c*"}},
        ref_deep: "$t(test.a.b.c)",
      }
      rr = described_class::ResourceRewriter.new
      rr.prime(resfile("test", strings))
      got = rr.to_output(resfile("test", strings))
      expect(got).to eq(
        {
          "base" => [:s, "abc"],
          "md" => [:m, "a *b* c"],
          "mdp" => [:mp, "a\n\nb"],
          "ref_plain" => [:s, "@% @%", {t: "test.base"}, {t: "test.base"}],
          "ref_md" => [:m, "@% @%", {t: "test.base"}, {t: "test.md"}],
          "ref_mdp" => [:mp, "@% @%", {t: "test.base"}, {t: "test.mdp"}],
          "ref_mdp_deep" => [:mp, "@%", {t: "test.ref_mdp"}],
          "a" => {"b" => {"c" => [:m, "*c*"]}},
          "ref_deep" => [:m, "@%", {t: "test.a.b.c"}],
        },
      )
    end

    it "uses high-complexity formatters, even when refs are out-of-order" do
      strings = {
        s0: "xy",
        s1: "$t(test.s2)",
        s2: "*$t(test.s3)*",
        s3: "$t(test.s0)\n\nhi",
      }
      rr = described_class::ResourceRewriter.new
      rr.prime(resfile("test", strings))
      got = rr.to_output(resfile("test", strings))
      expect(got).to eq(
        {
          "s0" => [:s, "xy"],
          "s1" => [:mp, "@%", {t: "test.s2"}],
          "s2" => [:mp, "*@%*", {t: "test.s3"}],
          "s3" => [:mp, "@%\n\nhi", {t: "test.s0"}],
        },
      )
    end

    it "finds refs across namespaces" do
      strings1 = {
        s1: "$t(test2.s1)",
      }
      strings2 = {
        s1: "*hi*",
      }
      rr = described_class::ResourceRewriter.new
      rr.prime(resfile("test1", strings1), resfile("test2", strings2))
      got1 = rr.to_output(resfile("test1", strings1))
      got2 = rr.to_output(resfile("test2", strings2))
      expect(got2).to eq({"s1" => [:m, "*hi*"]})
      expect(got1).to eq({"s1" => [:m, "@%", {t: "test2.s1"}]})
    end

    it "handles and fixes colon-separated path names" do
      strings = {
        s1: "$t(test.s2)",
        s2: "*hi*",
      }
      rr = described_class::ResourceRewriter.new
      rr.prime(resfile("test", strings))
      got = rr.to_output(resfile("test", strings))
      expect(got).to eq({"s1" => [:m, "@%", {t: "test.s2"}], "s2" => [:m, "*hi*"]})
    end

    it "errors if to_output is called without being primed" do
      rr = described_class::ResourceRewriter.new
      rf1 = resfile("test1", {})
      rf2 = resfile("test2", {})
      expect do
        rr.to_output(rf1)
      end.to raise_error(Suma::InvalidPrecondition, /Must call #prime with 'test1' resource file/)
      rr.prime(rf1)
      expect { rr.to_output(rf1) }.to_not raise_error
      expect do
        rr.to_output(rf2)
      end.to raise_error(Suma::InvalidPrecondition, /Must call #prime with 'test2' resource file/)
      rr.prime(rf2)
      expect { rr.to_output(rf2) }.to_not raise_error
    end
  end

  describe "Formatter" do
    it "can figure out the formatter for a string" do
      expect(described_class::Formatter.for("ab")).to eq(described_class::Formatter::STR)
      expect(described_class::Formatter.for("a **b**")).to eq(described_class::Formatter::MD)
      expect(described_class::Formatter.for("a\n\nz\n\n-b\n-c\n")).to eq(described_class::Formatter::MD_MULTILINE)
      expect(described_class::Formatter.for("hi\n\n- a\n- b")).to eq(described_class::Formatter::MD_MULTILINE)
      expect(described_class::Formatter.for("hi\n- a\n- b")).to eq(described_class::Formatter::STR)
      expect(described_class::Formatter.for("- a\n- b")).to eq(described_class::Formatter::MD_MULTILINE)
      expect(described_class::Formatter.for("hi\n1. a\n2. b")).to eq(described_class::Formatter::STR)
      expect(described_class::Formatter.for("hi\n\n1. a\n2. b")).to eq(described_class::Formatter::MD_MULTILINE)
      expect(described_class::Formatter.for("1. a\n2. b")).to eq(described_class::Formatter::MD_MULTILINE)
    end

    it "uses an LRU" do
      orig_size = described_class::Formatter.lru.size
      s1 = SecureRandom.hex
      s2 = SecureRandom.hex
      expect(described_class::Formatter.for(s1)).to eq(described_class::Formatter::STR)
      expect(described_class::Formatter.for(s1)).to eq(described_class::Formatter::STR)
      expect(described_class::Formatter.lru).to have_attributes(size: orig_size + 1)
      expect(described_class::Formatter.for(s2)).to eq(described_class::Formatter::STR)
      expect(described_class::Formatter.lru).to have_attributes(size: orig_size + 2)
    end
  end
end
