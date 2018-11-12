defmodule TdDfLib.AclLoader do
  @moduledoc """
  The Permissions context.
  """

  @acl_cache_resolver Application.get_env(:td_df, :acl_cache_resolver)
  @user_cache_resolver Application.get_env(:td_df, :user_cache_resolver)

  def get_roles_and_users(r_type, r_id) do
    r_type
    |> @acl_cache_resolver.get_acl_roles(r_id)
    |> Enum.map(fn role ->
        users = r_type
        |> @acl_cache_resolver.get_acl_role_users(r_id, role)
        |> Enum.map(fn user_id ->
            user_id
            |> @user_cache_resolver.get_user
            |> Map.take([:full_name])
            |> Map.put(:id, String.to_integer(user_id))
          end)
        {role, users}
      end)
    |> Enum.into(%{})
  end
end
