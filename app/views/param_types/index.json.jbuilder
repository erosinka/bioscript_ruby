json.array!(@param_types) do |param_type|
  json.extract! param_type, :id
  json.url param_type_url(param_type, format: :json)
end
