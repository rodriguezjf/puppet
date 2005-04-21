#!/usr/local/bin/ruby -w

# DISABLED
# I'm only working on services, not processes, right now

module Blink
    class State
        class ProcessRunning < State
            def retrieve
                running = 0
                regex = Regexp.new(@params[:pattern])
                begin
                    # this ps is only tested on Solaris
                    # XXX yeah, this definitely needs to be fixed...
                    %x{ps -ef -U #{@params[:user]}}.split("\n").each { |process|
                        if regex.match(process)
                            running += 1
                        end
                    }
                rescue
                    # this isn't correct, but what the hell
                    Blink::Message.new(
                        :level => :error,
                        :source => self.parent,
                        :message => "Failed to run ps"
                    )
                end

                self.state = running
                Blink.debug "there are #{running} #{self.parent} processes for start"
            end

            def <=>(other)
                self.state < 1
            end

            def fix
                require 'etc'
                # ruby is really cool
                uid = 0
                if @params[:user].is_a? Integer
                    uid = @params[:user]
                else
                    uid = Etc.getpwnam(@params[:user]).uid
                end
                Kernel.fork {
                    Process.uid = uid
                    Process.euid = uid
                    string = @params[:binary] + (@params[:arguments] || "")
                    Blink::Message.new(
                        :level => :notice,
                        :source => self.parent,
                        :message => "starting"
                    )
                    Kernel.exec(string)
                }
            end
        end
    end
	class Type
		class BProcess < Type
			attr_reader :stat, :path
			@parameters = [:start, :stop, :user, :pattern, :binary, :arguments]
            @name = :process

			@namevar = :pattern

			Blink::Relation.new(self, Blink::Operation::Start, {
				:user => :user,
				:pattern => :pattern,
				:binary => :binary,
				:arguments => :arguments
			})

			Blink::Relation.new(self, Blink::Operation::Stop, {
				:user => :user,
				:pattern => :pattern
			})

		end # Blink::Type::BProcess
	end # Blink::Type

end
