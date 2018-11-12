defmodule TdDfLib.TemplatePreprocessor do
  @moduledoc false

  alias TdDfLib.AclLoader
  alias TdDfLib.Permissions

  def preprocess_templates(templates, ctx \\ %{})
  def preprocess_templates(templates,
    %{resource_type: resource_type, resource_id: resource_id} = ctx) do
    user_roles = AclLoader.get_roles_and_users(resource_type, resource_id)
    ctx = Map.put(ctx, :user_roles, user_roles)
    change_templates([], templates, ctx)
  end
  def preprocess_templates(templates, ctx) do
    change_templates([], templates, ctx)
  end

  defp change_templates(acc, [head|tail], ctx) do
    acc
    |> change_template(head, ctx)
    |> change_templates(tail, ctx)
  end
  defp change_templates(acc, [], _context), do: acc

  defp change_template(acc, template, ctx) do
    content = change_fields([], template.content, ctx)
    processed = Map.put(template, :content, content)
    [processed|acc]
  end

  defp change_fields(acc, [head|tail], ctx) do
    acc
    |> change_field(head, ctx)
    |> change_fields(tail, ctx)
  end
  defp change_fields(acc, [], _ctx), do: acc

  defp change_field(acc, %{"name" => "_confidential"} = field, ctx) do
    redefined_field = field
    |> Map.put("type", "list")
    |> Map.put("widget", "checkbox")
    |> Map.put("required", false)
    |> Map.put("values", ["Si", "No"])
    |> Map.put("default", "No")
    |> Map.put("disabled", is_confidential_field_disabled?(ctx))
    |> Map.drop(["meta"])
    acc ++ [redefined_field]
  end
  defp change_field(acc, %{"type" => type, "meta" => meta} = field, ctx) do
    field = case {type, meta} do
      {"map_list", %{"role" => role_name}} ->
        user = Map.get(ctx, :user, nil)
        user_roles = Map.get(ctx, :user_roles, [])
        apply_role_meta(field, user, role_name, user_roles)
      _ -> field
    end
    field_without_meta = Map.delete(field, "meta")
    acc ++ [field_without_meta]
  end
  defp change_field(acc, %{} = field, _ctx),  do: acc ++ [field]

  defp is_confidential_field_disabled?(%{user: %{is_admin: true}}), do: false
  defp is_confidential_field_disabled?(%{
    resource_type: "domain", resource_id: domain_id, user: user}) do
    !Permissions.authorized?(user, :manage_confidential_business_concepts, domain_id)
  end
  defp is_confidential_field_disabled?(_), do: true

  defp apply_role_meta(%{} = field, user, role_name, user_roles)
    when not is_nil(user) and
         not is_nil(role_name) do
    users = Map.get(user_roles, role_name, [])
    field = Map.put(field, "values", users)
    case Enum.find(users, &(&1.id == user.id)) do
      nil -> field
      u -> Map.put(field, "default", u.full_name)
    end
  end
  defp apply_role_meta(field, _user, _role, _user_roles), do: field

end
