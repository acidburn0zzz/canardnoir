# frozen_string_literal: true

class VitaFact < NameFact
  belongs_to :vita

  def name_language_facts
    NameLanguageFact.joins(:language).where(vita_id: vita_id, analysis_id: analysis_id)
                    .order('languages.category', total_months: :desc,
                                                 total_commits: :desc,
                                                 total_activity_lines: :desc)
  end
end
