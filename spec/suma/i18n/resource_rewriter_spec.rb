# frozen_string_literal: true

require "suma/i18n"

RSpec.describe Suma::I18n::ResourceRewriter do
  def resfile(ns, h)
    return described_class::ResourceFile.new(h.deep_stringify_keys, namespace: ns)
  end

  def rewrite(s)
    rr = described_class.new
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
    expect(rewrite("{{x-2_3.y.z}}")).to eq([:s, "@%", {k: "x-2_3.y.z"}])
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
    end.to raise_error(Suma::I18n::InvalidInput)
  end

  it "errors if the json is not strings and hashes only" do
    expect do
      described_class.new.prime(resfile("test", {s: ["abc"]}))
    end.to raise_error(Suma::I18n::InvalidInput)
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
    rr = described_class.new
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
    rr = described_class.new
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
    rr = described_class.new
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
    rr = described_class.new
    rr.prime(resfile("test", strings))
    got = rr.to_output(resfile("test", strings))
    expect(got).to eq({"s1" => [:m, "@%", {t: "test.s2"}], "s2" => [:m, "*hi*"]})
  end

  it "errors if to_output is called without being primed" do
    rr = described_class.new
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
