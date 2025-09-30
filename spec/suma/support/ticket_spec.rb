# frozen_string_literal: true

RSpec.describe "Suma::Support::Ticket", :db do
  let(:described_class) { Suma::Support::Ticket }

  describe "#sync_to_front" do
    it "creates a discussion conversation" do
      ticket = Suma::Fixtures.support_ticket.create
      req = stub_request(:post, "https://api2.frontapp.com/conversations").
        with(
          body: {
            "comment" => {"body" => ticket.body},
            "inbox_id" => "inb_123",
            "subject" => ticket.subject,
            "type" => "discussion",
          },
          headers: {"Content-Type" => "application/x-www-form-urlencoded"},
        ).
        to_return(fixture_response("front/conversation_create"))
      ticket.sync_to_front
      expect(ticket.refresh).to have_attributes(front_id: "cnv_yo1kg5q")
      expect(req).to have_been_made
    end

    it "includes attached uploaded files" do
      ticket = Suma::Fixtures.support_ticket.create(subject: "Hello")
      ticket.add_uploaded_file(
        Suma::Fixtures.uploaded_file.uploaded_bytes("xyz", "text/html", filename: "im.html").create,
      )

      # rubocop:disable Layout/LineLength
      req = stub_request(:post, "https://api2.frontapp.com/conversations").
        with do |req|
        expect(req.body).to include("Content-Disposition: form-data; name=\"type\"\r\n\r\ndiscussion")
        expect(req.body).to include("name=\"inbox_id\"\r\n\r\ninb_123")
        expect(req.body).to include("name=\"subject\"\r\n\r\nHello")
        expect(req.body).to include("name=\"attachments[0]\"; filename=\"im.html\"\r\nContent-Type: text/html\r\n\r\nxyz")
      end.to_return(fixture_response("front/conversation_create"))
      # rubocop:enable Layout/LineLength

      ticket.sync_to_front
      expect(req).to have_been_made
    end

    it "noops if the front id is set" do
      ticket = Suma::Fixtures.support_ticket.create(front_id: "abc")
      expect { ticket.sync_to_front }.to_not(change { ticket.front_id })
    end
  end
end
