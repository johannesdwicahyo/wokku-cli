# frozen_string_literal: true

class FakeCable
  attr_reader :sent

  def initialize(scripted_messages: [])
    @sent = []
    @on_message = ->(_) {}
    @scripted = scripted_messages
  end

  def send_message(payload)
    @sent << payload
  end

  def on_message(&block)
    @on_message = block
  end

  def pump(_t = 0.05)
    if (msg = @scripted.shift)
      @on_message.call(msg)
    end
  end

  def close
  end
end
