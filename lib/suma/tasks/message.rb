# frozen_string_literal: true

require "rake/tasklib"

require "suma/tasks"

class Suma::Tasks::Message < Rake::TaskLib
  def initialize
    super
    namespace :message do
      desc "Render the specified message using the given language and transport. " \
           "If :out is - or blank, write to stdout, otherwise treat it as a filename."
      task :render, [:template_class, :out, :language, :transport] do |_t, args|
        template_class_name = args[:template_class] or
          raise "Provide the template class name (NewMember or new_member) as the first argument"
        require "suma"
        Suma.load_app?

        feedback = $stderr
        use_stdout = args[:out].blank? || args[:out] == "-"
        out = use_stdout ? $stdout : File.open(args[:out], "w")

        delivery = Suma::Message::Delivery.preview(
          template_class_name,
          commit: true,
          transport: args[:transport] || "email",
          language: args[:language],
        )

        feedback << "*** Created #{delivery.inspect}\n\n"
        body_for_out = if (htmlbod = delivery.body_with_mediatype("text/html"))
                         htmlbod
        else
          delivery.bodies.first
       end
        delivery.bodies.reject { |b| b === body_for_out }.each do |body|
          feedback << body.content
          feedback << "\n\n"
        end

        feedback << "*** Writing #{body_for_out.mediatype} to #{out.path}.\n"
        out << body_for_out.content
        out << "\n"
        out.close unless use_stdout
      end
    end
  end
end
