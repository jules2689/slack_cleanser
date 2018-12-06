require_relative 'cached_closed'
require 'terminal-notifier'

class Closer
  attr_reader :type

  def initialize(type, disallowed: ->(_x) { false }, fetch_channel_info: true)
    @type = type
    @cached_closed = CachedClosed.new(type)
    @client = Slack::Web::Client.new
    @fetch_channel_info = fetch_channel_info
    @disallowed = disallowed
  end

  def run
    t = Time.now
    conversations_to_leave = closable_conversations
    delta = Time.now - t

    puts "Done. Took #{delta}s"
    puts "Total of #{all_conversations.size} #{@type} open, #{conversations_to_leave.size} to close"
    puts conversations_to_leave.map { |c| c.name || c.id }.join(',')

    unless conversations_to_leave.empty?
      TerminalNotifier.notify(
        conversations_to_leave.map { |c| c.name || c.id }.join(', '),
        title: "Slack #{@type} (#{delta})",
        subtitle: "#{all_conversations.size} #{@type} open, #{conversations_to_leave.size} to close"
      )
      close_conversations(conversations_to_leave)
    end
  ensure
    @cached_closed.save
  end

  private

  def all_conversations
    @all_conversations ||= begin
      convos = []
      t = Time.now
      puts "Loading conversations of type #{@type}"
      @client.conversations_list(limit: 500, types: @type, exclude_archived: true) do |response|
        convos += response.channels.select do |chan|
          next false if chan.respond_to?(:is_member) && !chan.is_member
          true
        end
      end
      convos
    end
  end

  def closable_conversations
    @closable_conversations ||= begin
      date = Time.now.strftime("%m_%d_%Y")
      conversations_to_leave = all_conversations.select do |chan|
        next false if @cached_closed.include?(chan.id)
        if @fetch_channel_info
          resp = cached("cache/convo_info/#{chan.id}_#{date}") { @client.conversations_info(channel: chan.id) }
          @disallowed.call(resp.channel)
        else
          @disallowed.call(chan)
        end
      end
      conversations_to_leave
    end
  end

  def close_conversations(conversations_to_leave)
    original_time = Time.now.to_i
    conversations_to_leave.each_with_index do |chan, idx|
      retriable do
        resp = case @type
        when 'im'
          puts "Closing IM #{chan.id}"
          @client.conversations_close(channel: chan.id)
        when 'public_channel', 'private_channel'
          puts "Leaving channel #{chan.name}"
          @client.channels_leave(channel: chan.id)
        end
        @cached_closed.add(chan.id) if resp.already_closed || resp.ok
        puts "[#{Time.now.to_i - original_time}] #{idx}. #{chan.name || chan.id} :: #{resp}"
      end
    end
  end

  def cached(file_name)
    if File.exist?(file_name)
      Marshal.load(File.binread(file_name))
    else
      result = yield
      File.open(file_name, 'wb') do |f|
        f.write(Marshal.dump(result))
      end
      result
    end
  end

  def retriable(retry_limit: 10, sleep_interval: 3)
    retries = 0
    begin
      yield
    rescue => err
      retries += 1
      if retries < retry_limit
        retries += 1
        sleep sleep_interval
        retry
      else
        raise err
      end
    end
  end
end
