require "rails_helper"
require "helpers/dashboard_helper_spec"

RSpec.describe DashboardController, type: :controller do
  let(:user) { create :user }
  let!(:program) { create :program, save_status: true }
  let!(:program_year) { create :program_year, program_id: program.id }
  let!(:learner_program) do
    create :learner_program, program: program,
                             decision_one: "Advanced",
                             decision_two: "Accepted",
                             program_year_id: program_year.id
  end
  let(:center) { create(:center, name: "Lagos", country: "Nigeria") }
  let(:cycle) { create(:cycle) }
  let(:cycle_center) do
    create(:cycle_center, center: center, cycle: cycle, program_id: program.id)
  end

  RSpec.configure do |config|
    config.include DashboardHelperSpec
  end

  describe "GET #cycle center metrics csv export" do
    before do
      stub_current_user(:user)
      get :sheet, params: { format: "csv", report_type: "cycle_metrics",
                            program_id: learner_program.program.id,
                            cycle: learner_program.cycle_center.cycle.cycle,
                            center: learner_program.cycle_center.center.name }
    end

    context "when cycle_center_metrics data is generated" do
      it "returns a non empty response" do
        expect(response.body).not_to be_empty
      end
      it "returns 200 status" do
        expect(response).to have_http_status(200)
      end
      it "zip file contains CSV files" do
        sheet_generated_data_one("week_one_cycle_metrics_report.csv",
                                 "lfa_to_learner_ratio_report.csv",
                                 "performance_and_output_quality_report.csv")
        sheet_generated_data_two("week_two_cycle_metrics_report.csv",
                                 "gender_distribution_report.csv",
                                 "learner_quantity_report.csv")
      end
      it "return application/zip header" do
        expect(response.header["Content-Type"]).to include "application/zip"
      end
    end
  end

  describe "GET #program metrics csv export" do
    before do
      stub_current_user(:user)
      get :sheet, params: { format: "csv", report_type: "program_metrics",
                            start_date: "2018-07-02", end_date: "2081-07-20" }
    end
    context "when program_metrics data is generated" do
      it "returns a non empty response" do
        expect(response.body).not_to be_empty
      end
      it "returns 200 status" do
        expect(response).to have_http_status(200)
      end
      it "return application/zip header" do
        expect(response.header["Content-Type"]).to include "application/zip"
      end
      it "zip file contains CSV files" do
        sheet_generated_data_one(
          "historical_center_and_gender_distribution_report.csv",
          "cycles_per_centre_report.csv",
          "lfa_to_learner_ratio_report.csv"
)
        sheet_generated_data_two(
          "program_outcome_metrics_week_one_report.csv",
          "program_outcome_metrics_week_two_report.csv",
          "learners_dispersion_report.csv"
)
      end
    end
  end
end
