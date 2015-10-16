# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151015131725) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "celery_tasksetmeta", force: :cascade do |t|
    t.string   "taskset_id", limit: 255
    t.binary   "result"
    t.datetime "date_done"
  end

  add_index "celery_tasksetmeta", ["taskset_id"], name: "celery_tasksetmeta_taskset_id_key", unique: true, using: :btree

  create_table "connections", force: :cascade do |t|
    t.integer  "user_id",        null: false
    t.text     "ip"
    t.text     "user_agent"
    t.text     "url"
    t.text     "referer"
    t.text     "method"
    t.text     "body"
    t.text     "content_length"
    t.text     "content_type"
    t.text     "query_string"
    t.datetime "date_done"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "jobs", force: :cascade do |t|
    t.integer "request_id", null: false
    t.integer "task_id"
  end

  create_table "plugins", force: :cascade do |t|
    t.text    "key"
    t.boolean "deprecated"
    t.string  "info"
    t.string  "info_dup"
    t.string  "name"
  end

  add_index "plugins", ["key"], name: "plugins_key_key", unique: true, using: :btree

  create_table "requests", force: :cascade do |t|
    t.integer  "plugin_id",  null: false
    t.integer  "user_id",    null: false
    t.string   "parameters"
    t.datetime "created_at"
    t.text     "error"
    t.integer  "status_id"
  end

  create_table "result_types", force: :cascade do |t|
    t.string "result_type", limit: 40, null: false
  end

  create_table "results", force: :cascade do |t|
    t.integer "job_id",         null: false
    t.text    "result"
    t.boolean "is_file"
    t.text    "path"
    t.text    "fname"
    t.integer "result_type_id"
  end

  create_table "statuses", force: :cascade do |t|
    t.string "status", limit: 40, null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.binary   "result"
    t.datetime "created_at"
    t.text     "traceback"
    t.integer  "status_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "email",      limit: 255
    t.datetime "created_at"
    t.string   "key",        limit: 255
    t.boolean  "is_service"
    t.string   "remote",     limit: 255
  end

  add_index "users", ["email"], name: "email_key", unique: true, using: :btree
  add_index "users", ["key"], name: "users_key_key", unique: true, using: :btree
  add_index "users", ["remote"], name: "users_remote_key", unique: true, using: :btree

  add_foreign_key "connections", "users", name: "jl_connection_user_id_fkey", on_delete: :cascade
  add_foreign_key "jobs", "requests", name: "jl_job_request_id_fkey", on_delete: :cascade
  add_foreign_key "jobs", "tasks", name: "jobs_task_id_fkey"
  add_foreign_key "requests", "plugins", name: "jl_plugin_request_plugin_id_fkey", on_delete: :cascade
  add_foreign_key "requests", "statuses", name: "plugin_requests_status_id_fkey"
  add_foreign_key "requests", "users", name: "jl_plugin_request_user_id_fkey", on_delete: :cascade
  add_foreign_key "results", "jobs", name: "jl_result_job_id_fkey", on_delete: :cascade
  add_foreign_key "results", "result_types", name: "results_result_type_id_fkey"
  add_foreign_key "tasks", "statuses", name: "tasks_status_id_fkey"
end
