# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :td_perms, redis_uri: "redis://localhost"
config :td_perms, permissions: [
  :is_admin
]
config :td_df_lib, df_cache: TdPerms.DynamicFormCache

import_config "#{Mix.env}.exs"