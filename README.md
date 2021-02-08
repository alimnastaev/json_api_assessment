![Elixir CI](https://github.com/alimnastaev/json_api_assessment/workflows/Elixir%20CI/badge.svg)

# JsonApi Assessment
### **LOGIC behind the code:**
#### - **StargazersController `"/add_new_repo"` endpoint:** 
1. We are checking if `user + repo_name` combination already exists/saved in the system. If NOT we are calling Github API endpoint `https://api.github.com/repos/#{username}/#{repo_name}/stargazers`to make sure `user + repo_name` valid and if yes we are collecting all stargazers.
2. We are saving all new `user + repo_name` combination into ETS table `:users` even if that repo has ZERO stars: <br />`{username, repo_name}`.
3. If user's repo has STARS we are saving all starred users into ETS table `:stargazers`: <br />`{"username", "repo_name", {"stargazer_name", "2021-01-24", "starred"}}`

#### - **StargazersController `"/new_and_former_stargazers"` endpoint:**
1. Since all stargazers already saved in our db, we just need to get that information providing this payload:
```json
{
    "username": "a username",
    "repo": "repo name",
    "start_range": "2011-01-07T00:00:00Z",
    "end_range": "2021-01-26T23:59:59Z"
}
```

####  - **cron.ex (will be implemented by Quantum)**
1. Hypothetically, at 6am getting all users from `:users` ETS table specifying this in our `config.ex`:
```elixir
config :eltoro_api, JsonApi.Scheduler,
  jobs: [
    #  6am everyday (time in UTC)
    {"0 10 * * *", {JsonApi.Cron, :run, []}}
  ]
```
and `application.ex`:
```elixir
    :ets.new(:users, [:bag, :public, :named_table])
    spawn(fn -> JsonApi.Cron.run() end)

    :ets.new(:stargazers, [:bag, :public, :named_table])
    spawn(fn -> JsonApi.Cron.run() end)
```
2. calling Github API endpoint with user's information to get stargazers for all users(those repos without stars yesterday might have stars)
3. Filtering those ones without stars and getting new starred and ustarred users
4. Comparing old data (what was in db) and new data (just got it from Github API call), merging all together and saving updated data into the ETS table `:stargazers`, basically preparing data for `"/new_and_former_stargazers"` endpoint
-------
### **HOW TO TEST**

#### - **StargazersController `"/add_new_repo"` endpoint:**

1. Run: `make setup_app`

2. Start the app: `make start_app`

3. POSTMAN collection folder has a correct request form or `curl` down below:
```curl
curl --location --request POST 'http://localhost:4000/api/add_new_repo' \
--header 'Content-Type: application/json' \
--data-raw '{
    "username": "octocat",
    "repo": "hello-world"
}'
```
or any repo... (experiment with starred and unstarred repos)

4. Star the same repo if it was unstarred

5. in `iex` run this `alias JsonApi.Cron` and then `Cron.run`
this module will be triggered as a cron job by Quantum(not implemented yet, but super easy to do it) every morning,
so running it from `iex` will be a clear representation for the cron job we expect  
So you should see yourself in the ETS table with a flag `starred`

6. Do opposite of #3 and run again #4:
if you were starred before you should see yourself as unstarred
(give some time before `Cron.run`: GitHub API is not picking up information quickly)

#### - **StargazersController `"/new_and_former_stargazers"` endpoint:**

```curl
curl --location --request POST 'http://localhost:4000/api/new_and_former_stargazers' \
--header 'Content-Type: application/json' \
--data-raw '{
    "username": "octocat",
    "repo": "hello-world",
    "start_range": "2011-01-07T00:00:00Z",
    "end_range": "2021-01-26T23:59:59Z"
}'
```
if a user `octacat` and `hello-world` repo not in the system you'll get a message saying, that user not in the system and you need to add them first. As soon as they added you run a request from POSTMAN collection or `curl` above. Expect this response:
```json
{
    "body": [
        "schacon starred",
        "adelcambre starred",
        "usergenic starred",
        "fdb starred",
        "darinel starred",
        "Willianvdv starred",
        "sul4bh starred",
        "preavy starred",
        "benjic starred",
        "hagiwaratakayuki starred",
        "stefanlasiewski starred",
        "hbjerry starred",
        "Visgean starred",
        "jiska starred",
        "hittudiv starred",
        "paulomichael starred",
        "garbagemonster starred",
        "minamipj9 starred",
        "coolhead starred",
        "Spaceghost starred",
        "RustyF starred",
        "chexee starred",
        "adrianbarbic starred",
        "yasirmturk starred",
        "moonshadows starred",
        "ff6347 starred",
        "LunaticNeko starred",
        "saadrehman starred",
        "allanmaio starred",
        "kapare starred"
    ],
    "errors": null
}
```

#### - **For local tests: `mix test test/json_api_web/controllers/stargazers_controller_test.exs`**
--------------------

#### **MAIN challenge of the assessment**
Looks like GitHub API doesn't have a specific endpoint to track `unstarred` stargazers.
So the main idea in my implementation is:
 <br />COMPARE `old data` (was collected yesterday by cron job or when starred repo was saved manually through the first endpoint) against `new data` (collected this morning by cron job).
If it exists ONLY in `old data`, I need update that record to `unstarred` and timestamp should be updated to `- 1` day.
I left some logs for the `Cron.run` execution to make it more clear what I mean.

#### **There is really cool CastParams Plug implementation along with Norm library and the pipechain approach in the controllers to avoid unnecessary `View` usage since it is just a JSON API. I believe that way the app having is much more clear and solid API functionality! I would love to discuss it during the interview!**

Thank you so much in advance!
