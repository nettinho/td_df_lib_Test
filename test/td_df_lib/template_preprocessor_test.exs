defmodule TdDfLib.TemplatePreprocessorTest do
  use ExUnit.Case
  doctest TdDfLib

  alias TdDfLib.TemplateValidation

  test "Preprocessor", %{conn: conn, swagger_schema: schema} do
    role_name = "role_name"

    @df_cache.clean_cache()
    @df_cache.put_template(%{
        id: 0,
        label: "some name",
        name: "some_name",
        is_default: false,
        content: [
          %{
            "name" => "dominio",
            "type" => "map_list",
            "label" => "label",
            "values" => [],
            "required" => false,
            "form_type" => "user_dropdown",
            "description" => "description",
            "meta" => %{"role" => role_name}
          }
        ]
    })

    role = MockTdAuthService.find_or_create_role(role_name)

    parent_domain = insert(:domain)
    {:ok, child_domain} = build(:child_domain, parent: parent_domain)
      |> Map.put(:parent_id, parent_domain.id)
      |> Map.take([:name, :description, :parent_id])
      |> Taxonomies.create_domain

    group_name = "group_name"
    group = MockTdAuthService.create_group(%{"group" => %{"name" => group_name}})
    group_user_name = "group_user_name"

    %{id: user_id} = MockTdAuthService.create_user(%{
      "user" => %{
        "user_name" => group_user_name,
        "full_name" => group_user_name,
        "is_admin" => false,
        "password" => "password",
        "email" => "nobody@bluetab.net",
        "groups" => [%{"name" => group_name}]
      }
    })

    user_name = "user_name"

    MockPermissionResolver.create_acl_entry(%{
      principal_id: group.id,
      principal_type: "group",
      resource_id: parent_domain.id,
      resource_type: "domain",
      role_id: role.id
    })

    group_id = User.gen_id_from_user_name(user_name)
    MockPermissionResolver.create_acl_entry(%{
      principal_id: group_id,
      principal_type: "user",
      resource_id: child_domain.id,
      resource_type: "domain",
      role_id: role.id
    })

    conn =
      get(conn, template_path(conn, :get_domain_templates, child_domain.id, preprocess: true))

    validate_resp_schema(conn, schema, "TemplatesResponse")
    stored_templates = json_response(conn, 200)["data"]

    values =
      stored_templates
      |> Enum.at(0)
      |> Map.get("content")
      |> Enum.at(0)
      |> Map.get("values")

    default =
      stored_templates
      |> Enum.at(0)
      |> Map.get("content")
      |> Enum.at(0)
      |> Map.get("default")

    assert values |> Enum.sort == [
      %{
        "full_name" => group_user_name,
        "id" => user_id,
        "user_name" => group_user_name
      }, %{
        "full_name" => user_name,
        "id" => group_id,
        "user_name" => user_name
      }] |> Enum.sort
    assert default == user_name
  end
end
