class UpdateClinicalTrials < ActiveJob::Base
  attr_reader :recurring

  after_perform do |job|
    job.reschedule if job.recurring
  end

  def perform(recurring = true)
    @recurring = recurring
    Source.where(source_type: 'PubMed').each do |source|
      resp = Scrapers::PubMed.call_pubmed_api(source.citation_id)
      clinical_trials = resp.clinical_trial_ids.uniq.map do |nct_id|
        ClinicalTrial.where(nct_id: nct_id).first_or_create
      end
      source.clinical_trials = clinical_trials
      source.save
      sleep 0.5
    end
  end

  def reschedule
    self.class.set(wait_until: next_week).perform_later
  end

  def next_week
    Date.today
      .beginning_of_week
      .next_week
      .midnight
  end
end
