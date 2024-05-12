# frozen_string_literal: true

require "spec_helper"

RSpec.describe "parsing FedEx xml" do
  before do
    address_klass = Class.new do
      include HappyMapper

      tag "Address"
      namespace "v2"
      element :city, String, tag: "City"
      element :state, String, tag: "StateOrProvinceCode"
      element :zip, String, tag: "PostalCode"
      element :countrycode, String, tag: "CountryCode"
      element :residential, HappyMapper::Boolean, tag: "Residential"
    end
    stub_const "Address", address_klass

    event_klass = Class.new do
      include HappyMapper

      tag "Events"
      namespace "v2"
      element :timestamp, String, tag: "Timestamp"
      element :eventtype, String, tag: "EventType"
      element :eventdescription, String, tag: "EventDescription"
      has_one :address, Address
    end
    stub_const "Event", event_klass

    packageweight_klass = Class.new do
      include HappyMapper

      tag "PackageWeight"
      namespace "v2"
      element :units, String, tag: "Units"
      element :value, Integer, tag: "Value"
    end
    stub_const "PackageWeight", packageweight_klass

    trackdetails_klass = Class.new do
      include HappyMapper

      tag "TrackDetails"
      namespace "v2"
      element   :tracking_number, String, tag: "TrackingNumber"
      element   :status_code, String, tag: "StatusCode"
      element   :status_desc, String, tag: "StatusDescription"
      element   :carrier_code, String, tag: "CarrierCode"
      element   :service_info, String, tag: "ServiceInfo"
      has_one   :weight, PackageWeight, tag: "PackageWeight"
      element   :est_delivery, String, tag: "EstimatedDeliveryTimestamp"
      has_many  :events, Event
    end
    stub_const "TrackDetails", trackdetails_klass

    notification_klass = Class.new do
      include HappyMapper

      tag "Notifications"
      namespace "v2"
      element :severity, String, tag: "Severity"
      element :source, String, tag: "Source"
      element :code, Integer, tag: "Code"
      element :message, String, tag: "Message"
      element :localized_message, String, tag: "LocalizedMessage"
    end
    stub_const "Notification", notification_klass

    transactiondetail_klass = Class.new do
      include HappyMapper

      tag "TransactionDetail"
      namespace "v2"
      element :cust_tran_id, String, tag: "CustomerTransactionId"
    end
    stub_const "TransactionDetail", transactiondetail_klass

    trackreply_klass = Class.new do
      include HappyMapper

      tag "TrackReply"
      namespace "v2"
      element   :highest_severity, String, tag: "HighestSeverity"
      element   :more_data, HappyMapper::Boolean, tag: "MoreData"
      has_many  :notifications, Notification, tag: "Notifications"
      has_many  :trackdetails, TrackDetails, tag: "TrackDetails"
      has_one   :tran_detail, TransactionDetail, tab: "TransactionDetail"
    end
    stub_const "TrackReply", trackreply_klass
  end

  it "parses xml with multiple namespaces" do
    track = TrackReply.parse(fixture_file("multiple_namespaces.xml"))

    aggregate_failures do
      expect(track.highest_severity).to eq("SUCCESS")
      expect(track.more_data).to be_falsey
      notification = track.notifications.first
      expect(notification.code).to eq(0)
      expect(notification.localized_message).to eq("Request was successfully processed.")
      expect(notification.message).to eq("Request was successfully processed.")
      expect(notification.severity).to eq("SUCCESS")
      expect(notification.source).to eq("trck")
      detail = track.trackdetails.first
      expect(detail.carrier_code).to eq("FDXG")
      expect(detail.est_delivery).to eq("2009-01-02T00:00:00")
      expect(detail.service_info).to eq("Ground-Package Returns Program-Domestic")
      expect(detail.status_code).to eq("OD")
      expect(detail.status_desc).to eq("On FedEx vehicle for delivery")
      expect(detail.tracking_number).to eq("9611018034267800045212")
      expect(detail.weight.units).to eq("LB")
      expect(detail.weight.value).to eq(2)
      events = detail.events
      expect(events.size).to eq(10)
      first_event = events[0]
      expect(first_event.eventdescription).to eq("On FedEx vehicle for delivery")
      expect(first_event.eventtype).to eq("OD")
      expect(first_event.timestamp).to eq("2009-01-02T06:00:00")
      expect(first_event.address.city).to eq("WICHITA")
      expect(first_event.address.countrycode).to eq("US")
      expect(first_event.address.residential).to be_falsey
      expect(first_event.address.state).to eq("KS")
      expect(first_event.address.zip).to eq("67226")
      last_event = events[-1]
      expect(last_event.eventdescription).to eq("In FedEx possession")
      expect(last_event.eventtype).to eq("IP")
      expect(last_event.timestamp).to eq("2008-12-27T09:40:00")
      expect(last_event.address.city).to eq("LONGWOOD")
      expect(last_event.address.countrycode).to eq("US")
      expect(last_event.address.residential).to be_falsey
      expect(last_event.address.state).to eq("FL")
      expect(last_event.address.zip).to eq("327506398")
      expect(track.tran_detail.cust_tran_id).to eq("20090102-111321")
    end
  end
end
