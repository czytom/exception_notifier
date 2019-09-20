require 'logger'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/module/attribute_accessors'
require 'exception_notifier/base_notifier'

module ExceptionNotifier
  autoload :EmailNotifier, 'exception_notifier/email_notifier'

  class UndefinedNotifierError < StandardError; end
  # Define logger
  mattr_accessor :logger
  @@logger = Logger.new(STDOUT)

  # Define a set of exceptions to be ignored, ie, dont send notifications when any of them are raised.
  mattr_accessor :ignored_exceptions

  @@ignored_exceptions = %w[]

  mattr_accessor :testing_mode
  @@testing_mode = false

  class << self
    # Store conditions that decide when exceptions must be ignored or not.
    @@ignores = []
    # Store notifiers that send notifications when exceptions are raised.
    @@notifiers = {}

    def testing_mode!
      self.testing_mode = true
    end

    def notify_exception(exception, options = {}, &block)
      return false if ignored_exception?(options[:ignore_exceptions], exception)
      return false if ignored?(exception, options)

      selected_notifiers = options.delete(:notifiers) || notifiers
      [*selected_notifiers].each do |notifier|
        fire_notification(notifier, exception, options.dup, &block)
      end
      true
    end

    def register_exception_notifier(name, notifier_or_options)
      if notifier_or_options.respond_to?(:call)
        @@notifiers[name] = notifier_or_options
      elsif notifier_or_options.is_a?(Hash)
        create_and_register_notifier(name, notifier_or_options)
      else
        raise ArgumentError, "Invalid notifier '#{name}' defined as #{notifier_or_options.inspect}"
      end
    end

    alias add_notifier register_exception_notifier

    def unregister_exception_notifier(name)
      @@notifiers.delete(name)
    end

    def registered_exception_notifier(name)
      @@notifiers[name]
    end

    def notifiers
      @@notifiers.keys
    end

    # Adds a condition to decide when an exception must be ignored or not.
    #
    #   ExceptionNotifier.ignore_if do |exception, options|
    #     not options['env'].production?
    #   end

    def ignore_if(&block)
      @@ignores << block
    end

    private

    def ignored?(exception, options)
      @@ignores.any? { |condition| condition.call(exception, options) }
    rescue Exception => e
      raise e if @@testing_mode
      logger.warn "An error occurred when evaluating an ignore condition. #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
      false
    end

    def ignored_exception?(ignore_array, exception)
      all_ignored_exceptions = (Array(ignored_exceptions) + Array(ignore_array)).map(&:to_s)
      exception_ancestors = exception.class.ancestors.map(&:to_s)
      !(all_ignored_exceptions & exception_ancestors).empty?
    end

    def fire_notification(notifier_name, exception, options, &block)
      notifier = registered_exception_notifier(notifier_name)
      notifier.call(exception, options, &block)
    rescue Exception => e
      raise e if @@testing_mode
      logger.warn "An error occurred when sending a notification using '#{notifier_name}' notifier. #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
      false
    end

    def create_and_register_notifier(name, options)
      notifier_classname = "#{name}_notifier".camelize
      notifier_class = ExceptionNotifier.const_get(notifier_classname)
      notifier = notifier_class.new(options)
      register_exception_notifier(name, notifier)
    rescue NameError => e
    end
  end
end
