# frozen_string_literal: true

module Wokku
  module Registry
    COMMANDS = {}

    module_function

    def register(name, desc, &block)
      COMMANDS[name] = { desc: desc, handler: block }
    end
  end
end
