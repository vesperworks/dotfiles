-- tests/test_romaji_label_spec.lua
-- Layer 1: ローマ字ラベルの純粋ロジックテスト

describe("romaji_label", function()
  local romaji

  before_each(function()
    romaji = require("vw.migemo")
  end)

  describe("kana_to_romaji テーブル", function()
    it("ひらがな清音が変換できる", function()
      assert.are.equal("a", romaji.kana_to_romaji["あ"])
      assert.are.equal("ka", romaji.kana_to_romaji["か"])
      assert.are.equal("sa", romaji.kana_to_romaji["さ"])
    end)

    it("カタカナも変換できる", function()
      assert.are.equal("a", romaji.kana_to_romaji["ア"])
      assert.are.equal("ka", romaji.kana_to_romaji["カ"])
    end)

    it("濁音が変換できる", function()
      assert.are.equal("ga", romaji.kana_to_romaji["が"])
      assert.are.equal("za", romaji.kana_to_romaji["ざ"])
    end)

    it("半濁音が変換できる", function()
      assert.are.equal("pa", romaji.kana_to_romaji["ぱ"])
    end)
  end)

  describe("youon テーブル", function()
    it("拗音が変換できる", function()
      assert.are.equal("kya", romaji.youon["きゃ"])
      assert.are.equal("sya", romaji.youon["しゃ"])
      assert.are.equal("tya", romaji.youon["ちゃ"])
    end)
  end)

  describe("compute_suffix", function()
    it("ひらがなの残りローマ字を返す", function()
      -- 「さくら」で「sa」を検索 → suffix は「kura」
      local suffix = romaji.compute_suffix("さくら", "sa")
      assert.are.equal("kura", suffix)
    end)

    it("検索入力がマッチしない場合は nil", function()
      local suffix = romaji.compute_suffix("あいう", "ka")
      assert.is_nil(suffix)
    end)

    it("残りがない場合は nil", function()
      local suffix = romaji.compute_suffix("あ", "a")
      assert.is_nil(suffix)
    end)

    it("促音を正しく処理する", function()
      -- 「きって」で「ki」を検索 → suffix は「tte」(促音t + て=te)
      local suffix = romaji.compute_suffix("きって", "ki")
      assert.are.equal("tte", suffix)
    end)

    it("拗音を正しく処理する", function()
      -- 「しゃしん」で「sya」を検索 → suffix は「sin」
      local suffix = romaji.compute_suffix("しゃしん", "sya")
      assert.are.equal("sin", suffix)
    end)

    it("漢字はフォールバック(nil)を返す", function()
      local suffix = romaji.compute_suffix("東京", "")
      assert.is_nil(suffix)
    end)
  end)
end)
