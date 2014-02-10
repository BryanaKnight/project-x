class User < ActiveRecord::Base
  has_many :foods
  has_many :stats
  has_one :goal

  def self.from_omniauth(auth)
    where(auth.slice("provider", "uid")).first || create_from_omniauth(auth)
  end

  def self.create_from_omniauth(auth)
    create! do |user|
      user.provider = auth["provider"]
      user.uid = auth["uid"]
      user.name = auth["info"]["name"]
      user.token = auth["extra"]["access_token"].token
      user.secret = auth["extra"]["access_token"].secret
    end
  end

  def fitbit_stats
    @fitbit_status ||= Activity.make_request(self)
  end

  def user_goal
    @goal ||= Goal.where(user_id: self.id).first
  end

  def calorie_total_for(date)
    if todays_foods(date).empty?
      0
    else
      (todays_foods(date).collect { |food| food.calories }.inject(:+)).round(0)
    end
  end

  # def daily_calorie_total
  #   (foods.collect { |food| food.calories }.inject(:+)).round(0)
  # end

  def protein_total_for(date)
    if todays_foods(date).empty?
      0
    else
      (todays_foods(date).collect { |food| food.protein }.inject(:+)).round(0)
    end
  end

  def fiber_total_for(date)
    if todays_foods(date).empty?
      0
    else
      (todays_foods(date).collect { |food| food.fiber }.inject(:+)).round(0)
    end
  end

  def fat_total_for(date)
    if todays_foods(date).empty?
      0
    else
      (todays_foods(date).collect { |food| food.fat }.inject(:+)).round(0)
    end
  end

  def carb_total_for(date)
    if todays_foods(date).empty?
      0
    else
      (todays_foods(date).collect { |food| food.carbs }.inject(:+)).round(0)
    end
  end

  def average_steps
    stats.average('steps').to_f
  end

  def average_sleep
    stats.average('sleep').to_f
  end

  def achievement
    @achievement ||= Achievement.new(self)
  end

  def todays_foods(date)
    foods.where(consumed_on: date)
  end

  def json
    {
      "steps" => steps_array
    }.to_json
  end

  def steps_array
    if user_goal.steps == 0
      [0,0]
    elsif user_goal.steps < fitbit_stats.steps
      [fitbit_stats.steps, 0]
    else
      [fitbit_stats.steps, (user_goal.steps - fitbit_stats.steps)]
    end
  end

end
