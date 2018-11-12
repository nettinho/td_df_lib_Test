defmodule TdDf.AclLoader.MockAclLoaderResolver do
  @moduledoc """
  A mock permissions resolver for simulating Acl and User Redis helpers
  """
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: :MockAclRoles)
    Agent.start_link(fn -> %{} end, name: :MockAclRoleUsers)
    Agent.start_link(fn -> %{} end, name: :MockUsers)
  end

  def set_acl_roles(r_type, r_id, roles) do
    Agent.update(:MockAclRoles, & Map.put(&1, {r_type, r_id}, roles))
  end

  def get_acl_roles(r_type, r_id) do
    :MockAclRoles
    |> Agent.get(& &1)
    |> Map.get({r_type, r_id}, [])
  end

  def set_acl_role_users(r_type, r_id, role, users) do
    Agent.update(:MockAclRoleUsers, & Map.put(&1, {r_type, r_id, role}, users))
  end

  def get_acl_role_users(r_type, r_id, role) do
    :MockAclRoleUsers
    |> Agent.get(& &1)
    |> Map.get({r_type, r_id, role}, [])
  end

  def put_user(user_id, user) do
    Agent.update(:MockUsers, & Map.put(&1, user_id, user))
  end

  def get_user(user_id) do
    :MockUsers
    |> Agent.get(& &1)
    |> Map.get(user_id)
  end

end
