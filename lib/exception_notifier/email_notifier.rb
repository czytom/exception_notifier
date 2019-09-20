require 'pony'
module ExceptionNotifier
  class EmailNotifier
    DEFAULT_OPTIONS = {
      sender_address: %("Exception Notifier" <exception.notifier@example.com>),
      exception_recipients: [],
      email_prefix: '[ERROR] ',
      email_format: :text,
      verbose_subject: true,
      normalize_subject: false,
      mailer_settings: nil,
      template_path: 'templates',
    }.freeze

    def initialize(options)
      @options = DEFAULT_OPTIONS.merge(options)
    end

    def self.normalize_digits(string)
      string.gsub(/[0-9]+/, 'N')
    end

    def call(exception, options = {})
      @exception = exception
      @backtrace = exception.backtrace || []
      @timestamp = Time.now
      @sections  = @options[:sections]
      @data = options[:data] 
     send
    end

    private

    def send
      options =  {:to => @options[:exception_recipients], :from => @options[:sender_address], :subject => compose_subject, :body => compose_body}
      Pony.mail(:to => @options[:exception_recipients], :from => @options[:sender_address], :subject => compose_subject, :body => compose_body)
    end

    def compose_subject
      subject = @options[:email_prefix].to_s.dup
      subject << " (#{@exception.class})"
      subject << " #{@exception.message.inspect}" if @options[:verbose_subject]
      subject = EmailNotifier.normalize_digits(subject) if @options[:normalize_subject]
      subject.length > 120 ? subject[0...120] + '...' : subject
    end

    def truncate(string, max)
      string.length > max ? "#{string[0...max]}..." : string
    end

    def safe_encode(value)
      value.encode('utf-8', invalid: :replace, undef: :replace, replace: '_')
    end

    def compose_body
      body = []
      body << "Timestamp: #{@timestamp}\n\n"
      body << "BACKTRACE:\n"
      body << @backtrace << "\n\n"
      body << "Additional data:\n"
    end
  end
end

