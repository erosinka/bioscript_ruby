json.array!(@result_types) do |result_type|
  json.extract! result_type, :id
  json.url result_type_url(result_type, format: :json)
end
