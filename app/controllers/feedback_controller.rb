class FeedbackController < ApplicationController
  before_action :get_reflection
  skip_before_action :redirect_non_andelan
  include FeedbackControllerHelper

  def get_learner_feedback
    learner_feedback = Feedback.find_learner_feedback(params[:details])
    render json: learner_feedback
  end

  def save_feedback
    saved_feedback = Feedback.create_or_update feedback_information
    assessment_info = get_feedback_assessment_info(
      saved_feedback.assessment_id
    )
    bootcamper_info = get_bootcamper_details(
      saved_feedback.learner_program_id
    )

    render json: {
      assessment_name: assessment_info.name,
      bootcamper_email: bootcamper_info.email,
      assessment_id: saved_feedback.assessment_id,
      phase_id: saved_feedback.phase_id
    }
  end

  def feedback_details
    learner_program_id = params[:learner_program_id]
    learner_phases = LearnerProgram.get_phase_impression(learner_program_id)
    if learner_program_id
      render json: learner_phases
    else
      render template: "no_access/index"
    end
  end

  def get_feedback_assessment_info(assessment_id)
    Assessment.find_by(id: assessment_id)
  end

  def get_bootcamper_details(learner_program_id)
    LearnerProgram.find(learner_program_id).bootcamper
  end

  def get_lfa_feedback
    render json: lfa_feedback.empty? ? feedback_nil : feedback
  end

  private

  def phase_ids
    learner_program.program.phases.pluck("id")
  end

  def framework_criterium_id
    assessment.framework_criterium_id
  end

  def framework_criterium
    FrameworkCriterium.find(framework_criterium_id)
  end

  def feedback_nil
    {
      phase: Phase.find(params[:phase_id]).name,
      framework: framework_criterium.framework.name,
      output: assessment.name,
      all_phases: all_phases,
      all_frameworks: Framework.all.pluck("id", "name"),
      assessments: group_outputs_by_phases(phase_ids)
    }
  end

  def feedback
    {
      phase: Phase.find(lfa_feedback[0].phase_id).name,
      framework: framework_criterium.framework.name,
      output: assessment.name,
      all_phases: all_phases,
      all_frameworks: Framework.all.pluck("id", "name"),
      assessments: group_outputs_by_phases(phase_ids),
      impression: Impression.find(lfa_feedback[0].impression_id).name,
      all_impresions: Impression.all.pluck("name"),
      details: lfa_feedback[0].comment,
      learner_feedback_id: lfa_feedback[0].id,
      is_multiple: lfa_feedback.count > 1,
      learner_feedback: lfa_feedback
    }
  end

  def all_phases
    Program.find(learner_program.program_id).
      phases.pluck("id", "name")
  end

  def lfa_feedback
    Feedback.find_learner_feedbacks(details)
  end

  def assessment
    Assessment.find(params[:assessment_id])
  end

  def learner_email
    session[:current_user_info][:email]
  end

  def bootcamper
    Bootcamper.find_by(email: learner_email)
  end

  def learner_program
    LearnerProgram.get_latest_learner_program(bootcamper.id)
  end

  def details
    {
      learner_program_id: learner_program.id,
      assessment_id: params[:assessment_id],
      phase_id: params[:phase_id]
    }
  end

  def feedback_information
    params.require(:details).
      permit(
        :learner_program_id,
        :comment,
        :phase_id,
        :impression_id,
        :output_submissions_id,
        :assessment_id,
        :finalized
      )
  end

  def group_outputs_by_phases(phase_ids)
    outputs = {}
    phase_ids.each do |phase_id|
      outputs[phase_id] = {}
      assessments = Assessment.includes(:phases).where(phases: { id: phase_id })
      assessments.each do |assessment|
        framework = assessment.framework_criterium.framework_id
        unless outputs[phase_id][framework]
          outputs[phase_id][framework] = []
        end
        outputs[phase_id][framework] << [assessment.id, assessment.name]
      end
    end
    outputs
  end
end
