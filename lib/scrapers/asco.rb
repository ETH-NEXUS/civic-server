require 'net/http'
require 'uri'

module Scrapers
  class Asco
    def self.run
      ActiveRecord::Base.transaction do
        ::Source.all.each do |source|
          populate_source_fields(source)
        end
      end
    end

    def self.get_citations_from_asco_abstract_id(id)
      resp = call_asco_query_api_by_asco_abstract_id(id)
      resp.citations
    end

    def self.get_citation_from_asco_id(id)
      resp = call_asco_query_api_by_asco_id(id)
      resp.citations.first
    end

    def self.populate_source_fields(source)
      record_resp = call_asco_abstract_api(source.citation_id)
      query_resp = call_asco_query_api_by_asco_id(source.citation_id)
      source.description = get_citation_from_asco_id(source.citation_id)
      source.asco_presenter = record_resp.presenter
      source.asco_abstract_id = record_resp.asco_abstract_id
      source.publication_year = query_resp.publication_year
      source.journal = record_resp.journal
      source.name = record_resp.article_title
      ###source.abstract = resp.abstract
      nct_id = record_resp.nct_id
      if not nct_id.empty?
        source.clinical_trials << ClinicalTrial.where(nct_id: nct_id).first_or_create
      end
      source.save
    end

    def self.call_asco_query_api_by_asco_id(asco_id)
      http_resp = Util.make_get_request(query_url_for_asco_id(asco_id))
      AscoQueryResponse.new(http_resp)
    end

    def self.call_asco_query_api_by_asco_abstract_id(asco_abstract_id)
      http_resp = Util.make_get_request(query_url_for_asco_abstract_id(asco_abstract_id))
      AscoQueryResponse.new(http_resp)
    end

    def self.call_asco_record_api(asco_id)
      http_resp = Util.make_get_request(record_url_for_asco_id(asco_id))
      AscoRecordResponse.new(http_resp)
    end

    def self.call_asco_abstract_api(asco_id)
      http_resp = Util.make_get_request(abstract_url_for_asco_id(asco_id))
      AscoRecordResponse.new(http_resp)
    end

    private
    def self.query_url_for_asco_id(asco_id)
      "https://solr.asco.org/solr/ml/select?_format=json&wt=json&q=(_id:#{asco_id})"
    end

    def self.query_url_for_asco_abstract_id(asco_abstract_id)
     "https://solr.asco.org/solr/ml/select?_format=json&wt=json&q=(AbstID:#{asco_abstract_id})"
    end

    def self.record_url_for_asco_id(asco_id)
      "https://ml-couch.asco.org/records/#{asco_id}"
    end

    def self.abstract_url_for_asco_id(asco_id)
      "https://ml-couch.asco.org/abstracts/#{asco_id}"
    end
  end
end