# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::Message < Rake::TaskLib
  def initialize
    super()
    namespace :message do
      desc "Render the specified message using the given language and transport. " \
           "If :out is - or blank, write to stdout, otherwise treat it as a filename."
      task :render, [:template_class, :out, :language, :transport] do |_t, args|
        template_class_name = args[:template_class] or
          raise "Provide the template class name (NewMember or new_member) as the first argument"
        outpath = args[:out]
        outpath = nil if outpath.blank? || outpath == "-"
        if outpath
          html_io = File.open(outpath, "w")
          feedback_io = $stdout
        else
          html_io = $stdout
          feedback_io = $stderr
        end

        require "suma"
        Suma.load_app

        delivery = Suma::Message::Delivery.preview(
          template_class_name,
          commit: true,
          transport: args[:transport] || "sms",
          language: args[:language],
        )
        feedback_io << "*** Created MessageDelivery: #{delivery.values}\n\n"
        if (plainbod = delivery.body_with_mediatype("text/plain"))
          feedback_io << plainbod.content
          feedback_io << "\n\n"
        end
        if (htmlbod = delivery.body_with_mediatype("text/html"))
          if outpath
            feedback_io << "*** Writing HTML output to #{outpath}\n"
          else
            feedback_io << "*** Writing HTML output to stdout.\n"
            feedback_io << "*** Redirect it to a file (> temp.html), pass OUT to write it to a file (OUT=temp.html),\n"
            feedback_io << "*** or view it at /admin_api/v1/message_deliveries/last\n\n"
          end
          html_io << htmlbod.content
          html_io << "\n"
        end
      end
    end
  end
end
