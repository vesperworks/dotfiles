-- lua/vw/migemo.lua
-- cmigemo 連携・ローマ字ラベル
-- migemo-bridge.lua + romaji-label.lua を統合

local M = {}

-- =============================================
-- cmigemo 連携 (migemo-bridge)
-- =============================================

M._cache = {}

-- パスを動的に検出（環境非依存）
M.CMIGEMO_PATH = vim.fn.exepath("cmigemo")
M.DICT_PATH = (function()
  local path = vim.fn.exepath("cmigemo")
  if path == "" then return "" end
  local prefix = vim.fn.fnamemodify(path, ":h:h")
  local dict = prefix .. "/share/migemo/utf-8/migemo-dict"
  if vim.fn.filereadable(dict) == 0 then return "" end
  return dict
end)()

--- cmigemoが利用可能か判定
function M.is_available()
  return M.CMIGEMO_PATH ~= "" and M.DICT_PATH ~= ""
end

--- ローマ字→Vim正規表現パターンを取得（キャッシュあり）
function M.query(input)
  if not input or input == "" then return input end
  if M._cache[input] then return M._cache[input] end
  if not M.is_available() then return input end

  local result = vim.fn.system({
    M.CMIGEMO_PATH, "-d", M.DICT_PATH, "-v", "-q", "-w", input,
  })
  result = vim.trim(result)

  if result and result ~= "" then
    M._cache[input] = result
    return result
  end

  return input
end

-- =============================================
-- ローマ字ラベル (romaji-label)
-- =============================================

-- ひらがな/カタカナ → ローマ字変換テーブル（kunrei式 = cmigemo互換）
M.kana_to_romaji = {
  -- ひらがな清音
  ["あ"] = "a", ["い"] = "i", ["う"] = "u", ["え"] = "e", ["お"] = "o",
  ["か"] = "ka", ["き"] = "ki", ["く"] = "ku", ["け"] = "ke", ["こ"] = "ko",
  ["さ"] = "sa", ["し"] = "si", ["す"] = "su", ["せ"] = "se", ["そ"] = "so",
  ["た"] = "ta", ["ち"] = "ti", ["つ"] = "tu", ["て"] = "te", ["と"] = "to",
  ["な"] = "na", ["に"] = "ni", ["ぬ"] = "nu", ["ね"] = "ne", ["の"] = "no",
  ["は"] = "ha", ["ひ"] = "hi", ["ふ"] = "hu", ["へ"] = "he", ["ほ"] = "ho",
  ["ま"] = "ma", ["み"] = "mi", ["む"] = "mu", ["め"] = "me", ["も"] = "mo",
  ["や"] = "ya", ["ゆ"] = "yu", ["よ"] = "yo",
  ["ら"] = "ra", ["り"] = "ri", ["る"] = "ru", ["れ"] = "re", ["ろ"] = "ro",
  ["わ"] = "wa", ["を"] = "wo", ["ん"] = "n",
  -- ひらがな濁音
  ["が"] = "ga", ["ぎ"] = "gi", ["ぐ"] = "gu", ["げ"] = "ge", ["ご"] = "go",
  ["ざ"] = "za", ["じ"] = "zi", ["ず"] = "zu", ["ぜ"] = "ze", ["ぞ"] = "zo",
  ["だ"] = "da", ["ぢ"] = "di", ["づ"] = "du", ["で"] = "de", ["ど"] = "do",
  ["ば"] = "ba", ["び"] = "bi", ["ぶ"] = "bu", ["べ"] = "be", ["ぼ"] = "bo",
  -- ひらがな半濁音
  ["ぱ"] = "pa", ["ぴ"] = "pi", ["ぷ"] = "pu", ["ぺ"] = "pe", ["ぽ"] = "po",
  -- ひらがな小文字
  ["ぁ"] = "a", ["ぃ"] = "i", ["ぅ"] = "u", ["ぇ"] = "e", ["ぉ"] = "o",
  ["ゃ"] = "ya", ["ゅ"] = "yu", ["ょ"] = "yo",
  -- カタカナ清音
  ["ア"] = "a", ["イ"] = "i", ["ウ"] = "u", ["エ"] = "e", ["オ"] = "o",
  ["カ"] = "ka", ["キ"] = "ki", ["ク"] = "ku", ["ケ"] = "ke", ["コ"] = "ko",
  ["サ"] = "sa", ["シ"] = "si", ["ス"] = "su", ["セ"] = "se", ["ソ"] = "so",
  ["タ"] = "ta", ["チ"] = "ti", ["ツ"] = "tu", ["テ"] = "te", ["ト"] = "to",
  ["ナ"] = "na", ["ニ"] = "ni", ["ヌ"] = "nu", ["ネ"] = "ne", ["ノ"] = "no",
  ["ハ"] = "ha", ["ヒ"] = "hi", ["フ"] = "hu", ["ヘ"] = "he", ["ホ"] = "ho",
  ["マ"] = "ma", ["ミ"] = "mi", ["ム"] = "mu", ["メ"] = "me", ["モ"] = "mo",
  ["ヤ"] = "ya", ["ユ"] = "yu", ["ヨ"] = "yo",
  ["ラ"] = "ra", ["リ"] = "ri", ["ル"] = "ru", ["レ"] = "re", ["ロ"] = "ro",
  ["ワ"] = "wa", ["ヲ"] = "wo", ["ン"] = "n",
  -- カタカナ濁音
  ["ガ"] = "ga", ["ギ"] = "gi", ["グ"] = "gu", ["ゲ"] = "ge", ["ゴ"] = "go",
  ["ザ"] = "za", ["ジ"] = "zi", ["ズ"] = "zu", ["ゼ"] = "ze", ["ゾ"] = "zo",
  ["ダ"] = "da", ["ヂ"] = "di", ["ヅ"] = "du", ["デ"] = "de", ["ド"] = "do",
  ["バ"] = "ba", ["ビ"] = "bi", ["ブ"] = "bu", ["ベ"] = "be", ["ボ"] = "bo",
  -- カタカナ半濁音
  ["パ"] = "pa", ["ピ"] = "pi", ["プ"] = "pu", ["ペ"] = "pe", ["ポ"] = "po",
  -- カタカナ小文字
  ["ァ"] = "a", ["ィ"] = "i", ["ゥ"] = "u", ["ェ"] = "e", ["ォ"] = "o",
  ["ャ"] = "ya", ["ュ"] = "yu", ["ョ"] = "yo",
}

-- 拗音テーブル（2文字ペア → ローマ字）
M.youon = {
  -- ひらがな
  ["きゃ"] = "kya", ["きゅ"] = "kyu", ["きょ"] = "kyo",
  ["しゃ"] = "sya", ["しゅ"] = "syu", ["しょ"] = "syo",
  ["ちゃ"] = "tya", ["ちゅ"] = "tyu", ["ちょ"] = "tyo",
  ["にゃ"] = "nya", ["にゅ"] = "nyu", ["にょ"] = "nyo",
  ["ひゃ"] = "hya", ["ひゅ"] = "hyu", ["ひょ"] = "hyo",
  ["みゃ"] = "mya", ["みゅ"] = "myu", ["みょ"] = "myo",
  ["りゃ"] = "rya", ["りゅ"] = "ryu", ["りょ"] = "ryo",
  ["ぎゃ"] = "gya", ["ぎゅ"] = "gyu", ["ぎょ"] = "gyo",
  ["じゃ"] = "zya", ["じゅ"] = "zyu", ["じょ"] = "zyo",
  ["びゃ"] = "bya", ["びゅ"] = "byu", ["びょ"] = "byo",
  ["ぴゃ"] = "pya", ["ぴゅ"] = "pyu", ["ぴょ"] = "pyo",
  -- カタカナ
  ["キャ"] = "kya", ["キュ"] = "kyu", ["キョ"] = "kyo",
  ["シャ"] = "sya", ["シュ"] = "syu", ["ショ"] = "syo",
  ["チャ"] = "tya", ["チュ"] = "tyu", ["チョ"] = "tyo",
  ["ニャ"] = "nya", ["ニュ"] = "nyu", ["ニョ"] = "nyo",
  ["ヒャ"] = "hya", ["ヒュ"] = "hyu", ["ヒョ"] = "hyo",
  ["ミャ"] = "mya", ["ミュ"] = "myu", ["ミョ"] = "myo",
  ["リャ"] = "rya", ["リュ"] = "ryu", ["リョ"] = "ryo",
  ["ギャ"] = "gya", ["ギュ"] = "gyu", ["ギョ"] = "gyo",
  ["ジャ"] = "zya", ["ジュ"] = "zyu", ["ジョ"] = "zyo",
  ["ビャ"] = "bya", ["ビュ"] = "byu", ["ビョ"] = "byo",
  ["ピャ"] = "pya", ["ピュ"] = "pyu", ["ピョ"] = "pyo",
}

--- UTF-8文字を1文字取得
local function get_utf8_char(str, pos)
  local byte = str:byte(pos)
  if not byte then return nil, pos end
  local len = 1
  if byte >= 0xF0 then len = 4
  elseif byte >= 0xE0 then len = 3
  elseif byte >= 0xC0 then len = 2
  end
  return str:sub(pos, pos + len - 1), pos + len
end

--- テキストからローマ字を計算し、検索入力分をスキップした残りを返す
function M.compute_suffix(text, search_input)
  local romaji = ""
  local pos = 1

  while pos <= #text and #romaji < #search_input + 4 do
    local char, next_pos = get_utf8_char(text, pos)
    if not char then break end

    -- 促音チェック（っ/ッ）
    if char == "っ" or char == "ッ" then
      local next_char = get_utf8_char(text, next_pos)
      if next_char then
        local next_r = M.kana_to_romaji[next_char]
        if next_r then
          romaji = romaji .. next_r:sub(1, 1)
          pos = next_pos
          goto continue
        end
      end
      pos = next_pos
      goto continue
    end

    -- 拗音チェック（2文字ペア）
    local next_char = get_utf8_char(text, next_pos)
    if next_char then
      local pair = char .. next_char
      local youon_r = M.youon[pair]
      if youon_r then
        romaji = romaji .. youon_r
        pos = next_pos
        local _, after_next = get_utf8_char(text, pos)
        pos = after_next
        goto continue
      end
    end

    -- 通常の仮名変換
    local r = M.kana_to_romaji[char]
    if r then
      romaji = romaji .. r
    elseif char:byte() <= 127 then
      romaji = romaji .. char
    else
      if #romaji <= #search_input then
        return nil
      end
      break
    end

    pos = next_pos
    ::continue::
  end

  if romaji:sub(1, #search_input) == search_input then
    local suffix = romaji:sub(#search_input + 1)
    if suffix == "" then return nil end
    return suffix
  end

  return nil
end

function M.setup()
  -- migemo はセットアップ不要（flash.lua から直接 require される）
end

return M
