module LearnersHelper
  def get_output_percentage(link_uploaded, overall_asssessments)
    return 0 if overall_asssessments.zero?

    result = (link_uploaded / overall_asssessments.to_f) * 100
    result.positive? ? result.round : 0
  end

  def confirm_selected(database_value, current_value)
    "selected" if database_value == current_value
  end

  def format_date(date)
    date.to_date.strftime("%a, %e %B %Y")
  end

  def show_registered(program)
    created_at = program[:created_at]
    content_tag(:div, format_date(created_at),
                class: "registration-date-wrapper")
  end

  def show_history(program)
    date = program[:start_date]
    start_date = date.blank? ? "None" : format_date(date)
    program_name = program[:program].split(" ")[0].capitalize
    content_tag(:div, class: "cycle-history") do
      content_tag(:div, "#{program_name} #{program[:cycle]},
        #{program[:center]}") +
        content_tag(:div, start_date) +
        content_tag(:div, get_decision_status(1, program).to_s) +
        content_tag(:div, get_decision_status(2, program).to_s)
    end
  end

  def get_decision_status(stage, program)
    return "" unless program[:end_date]

    @program = program
    case stage
    when 1
      process_stage_one
    when 2
      process_stage_two
    end
  end

  def process_stage_one
    return "Week 1: N/A" if decision_one.nil? && Time.now > wait

    Time.now < wait ? "Week 1: Processing" : "Week 1: #{decision_one}"
  end

  def process_stage_two
    return "Week 2: N/A" if decision_two.nil?

    return filter_center_cycle unless filter_center_cycle.nil?

    ongoing ? "Week 2: Processing" : "Week 2: #{decision_two}"
  end

  def filter_center_cycle
    "Week 2: Processing" if @program[:center] == "Nairobi" &&
                            (@program[:cycle] == 37 || @program[:cycle] == 36)
  end

  def decision_one
    @program[:decision_one]
  end

  def decision_two
    @program[:decision_two]
  end

  def ongoing
    Time.now < wait && @program[:decision_one] == "Advanced"
  end

  def wait
    10.business_days.after(@program[:end_date].to_date)
  end
end
