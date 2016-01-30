String.class_eval do
    def is_i?
       !!(self =~ /\A[-+]?[0-9]+\z/)
    end
end