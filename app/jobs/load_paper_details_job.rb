class LoadPaperDetailsJob < ActiveJob::Base
  queue_as :meta

  def perform(paper)
    Rails.logger.info "Loading details for Paper [#{paper.body.state} #{paper.full_reference}]"
    detail = paper.body.scraper::Detail.new(paper.legislative_term, paper.reference).scrape
    originators = detail[:originators]

    unless originators[:parties].blank?
      # write parties
      originators[:parties].each do |party|
        Rails.logger.debug "+ Originator: #{party}"
        org = Organization.where('lower(name) = ?', party.mb_chars.downcase.to_s).first_or_create(name: party)
        unless paper.originator_organizations.include? org
          paper.originator_organizations << org
          paper.save
        end
      end
    end

    unless originators[:people].blank?
      # write people
      originators[:people].each do |name|
        Rails.logger.debug "+ Originator: #{name}"
        person = Person.where('lower(name) = ?', name.mb_chars.downcase.to_s).first_or_create(name: name)
        unless paper.originator_people.include? person
          paper.originator_people << person
          paper.save
        end
      end
    end
  end
end