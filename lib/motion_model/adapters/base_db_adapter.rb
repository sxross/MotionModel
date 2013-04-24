module MotionModel
  class BaseDBAdapter
    def initialize(options = {})
      @logger = options.delete(:logger)
      @options = options
      MotionModel::Store.config(self)
    end

    def log(sql, type, result)
      return if @options["log_#{type}".to_sym] == false
      if @logger
        @logger.call(sql, result.to_s)
      elsif @options[:ns_log] != false
        msg = "ExecSQL: #{sql}\nExecSQLResult: #{result.to_s}"
        NSLog(msg)
      end
    end
  end
end
