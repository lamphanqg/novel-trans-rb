require "open3"

module NovelTrans
  class CursorAgent
    MODEL = "gemini-3.7-flash-high".freeze

    def initialize(bin: ENV.fetch("CURSOR_BIN", "cursor"), model: ENV.fetch("CURSOR_MODEL", MODEL))
      @bin = bin
      @model = model
    end

    def translate(chinese, names: {})
      text = ask(build_prompt(chinese, names))
      raise Error, "cursor agent returned no Vietnamese text" if text.empty?

      text
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

    def name_block(names)
      return "" if names.empty?

      lines = names.sort.map { |chinese, vietnamese| "#{chinese} → #{vietnamese}" }
      "Use these names exactly:\n#{lines.join("\n")}\n"
    end
  end
end
