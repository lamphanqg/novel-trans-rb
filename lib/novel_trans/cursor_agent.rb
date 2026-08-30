require "open3"

module NovelTrans
  class CursorAgent
    MODEL = "gemini-3.7-flash-high".freeze
    NAMES_MARK = "===NOVEL_TRANS_NAMES===".freeze

    def initialize(bin: ENV.fetch("CURSOR_BIN", "cursor"), model: ENV.fetch("CURSOR_MODEL", MODEL))
      @bin = bin
      @model = model
    end

    def translate(chinese, names: {})
      text = ask(build_prompt(chinese, names))
      raise Error, "cursor agent returned no Vietnamese text" if text.empty?

      text
    end

    def translate_with_names(chinese, names: {})
      text = ask(build_vocab_prompt(chinese, names))
      split_translation(text)
    end

    def extract_names(chinese, vietnamese, locked: {})
      Vocab.parse(ask(build_extract_prompt(chinese, vietnamese, locked)))
    end

    private

    def ask(prompt)
      stdout, stderr, status = Open3.capture3(*command(prompt))
      unless status.success?
        raise Error, "cursor agent failed: #{stderr.empty? ? stdout : stderr}".strip
      end

      stdout.to_s.strip
    rescue Errno::ENOENT
      raise Error, "cursor not found. Install the Cursor CLI and log in."
    end

    def command(prompt)
      [
        @bin,
        "agent",
        "-p",
        "--mode", "ask",
        "--output-format", "text",
        "--trust",
        "--model", @model,
        "--workspace", NovelTrans.root,
        prompt
      ]
    end

    def build_prompt(chinese, names)
      <<~PROMPT
        Translate this Chinese web novel chapter to Vietnamese.
        Keep the title and paragraph breaks. Keep character names consistent.
        Print only the Vietnamese chapter. No commentary.
        #{name_block(names)}
        #{chinese}
      PROMPT
    end

    def build_vocab_prompt(chinese, names)
      <<~PROMPT
        Translate this Chinese web novel chapter to Vietnamese.
        Keep the title and paragraph breaks. Keep character names consistent.
        Print the Vietnamese chapter, then a line that is exactly #{NAMES_MARK},
        then a YAML mapping of proper names in this chapter (Chinese: Vietnamese).
        People, places, and unique technique or item names only.
        Omit names already listed. An empty mapping {} is allowed. No commentary.
        #{name_block(names)}
        #{chinese}
      PROMPT
    end

    def build_extract_prompt(chinese, vietnamese, locked)
      <<~PROMPT
        List proper names from this Chinese chapter and its Vietnamese translation.
        People, places, and unique technique or item names only.
        Print only a YAML mapping of Chinese: Vietnamese. No commentary.
        #{locked_block(locked)}
        Chinese:
        #{chinese}

        Vietnamese:
        #{vietnamese}
      PROMPT
    end

    def name_block(names)
      return "" if names.empty?

      lines = names.sort.map { |chinese, vietnamese| "#{chinese} → #{vietnamese}" }
      "Use these names exactly:\n#{lines.join("\n")}\n"
    end

    def locked_block(locked)
      return "" if locked.empty?

      lines = locked.sort.map { |chinese, vietnamese| "#{chinese}: #{vietnamese}" }
      "These names are already locked. Do not print them:\n#{lines.join("\n")}\n"
    end

    def split_translation(text)
      raise Error, "cursor agent returned no name list" unless text.include?(NAMES_MARK)

      vietnamese, yaml = text.split(NAMES_MARK, 2)
      vietnamese = vietnamese.to_s.strip
      raise Error, "cursor agent returned no Vietnamese text" if vietnamese.empty?

      [vietnamese, Vocab.parse(yaml)]
    end
  end
end
