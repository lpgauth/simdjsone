defmodule Simdjsone do
  def benchmarks do
    benchmarks_encode(1)
    benchmarks_encode(4)
    benchmarks_encode(16)
    benchmarks_decode(1)
    benchmarks_decode(4)
    benchmarks_decode(16)
    :ok
  end

  defp benchmarks_encode(p) do
    bin =
      "{\"id\":\"d4b5c697-41f3-4c1c-a3d5-5fd01b5ef2aa\",\"at\":1,\"imp\":[{\"id\":\"974090632\",\"banner\":{\"w\":300,\"h\":250}}],\"site\":{\"id\":\"12345\",\"domain\":\"sitedomain.com\",\"cat\":[\"IAB25-3\"],\"page\":\"https://sitedomain.com/page\",\"keywords\":\"lifestyle, humour\"},\"device\":{\"ua\":\"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.63 Safari/537.36\",\"ip\":\"131.34.123.159\",\"geo\":{\"country\":\"IRL\"},\"language\":\"en\",\"os\":\"Linux & UNIX\",\"js\":0,\"ext\":{\"remote_addr\":\"131.34.123.159\",\"x_forwarded_for\":\"\",\"accept_language\":\"en-GB;q=0.8,pt-PT;q=0.6,en;q=0.4,en-US;q=0.2,de;q=0.2,es;q=0.2,fr;q=0.2\"}},\"user\":{\"id\":\"57592f333f8983.043587162282415065\",\"ext\":{\"consent\":\"CO9A8QHPAbnHWBcADBENBJCoAAAAAAAAAAqIHKJU9VybLh0Dq4A170B0OAEYN_r_v40zigeds-8Myd-X3DsX50M7vFy6pr4AuR4km3CBIQFkHOmcTUmw6IkVrRPsak2Mr7NKJ7PEinsbe2dYEHtfn9VTuZKZr97s___zf_-___3_75f__-3_3_vp9UAAAABA5QAkgkDYAKAQRAAJIwKhQAhAuJDoBAAUUIwtE1hASuCmYVAR-ggYAIDUBGAECDEEGIIIAAAAAkgiAkAPBAAgCIBAACAFSAhAARoAgsAJAwCAAUA0LACKAIQJCDI4KjlICAiRaKCeSMASi72MMIQSigAAAAAAAA\",\"prebid\":{\"buyeruids\":{\"platform1\":\"C9446DA7-BB76-44B9-B260-77E16530AA03\",\"platform2\":\"6372709574547581900\",\"platform3\":\"456621142600017315\",\"platform4\":\"3952063610783032691\",\"platform5\":\"KX3KMRTI-11-ZMP\",\"platform6\":\"402e4b19ff476fb23de2c97ebe62a47b\",\"platform7\":\"bu7zD7LkVT2huSwTSvou\"}}}},\"ext\":{\"sub\":1221}}"

    IO.puts("parallel: #{p}")

    Benchee.run(
      %{
        "thaos" => fn -> :thoas.decode(bin) end,
        "jason" => fn -> Jason.decode(bin) end,
        "jiffy" => fn -> :jiffy.decode(bin, [:return_maps]) end,
        "simdjsone" => fn -> :simdjson.decode(bin) end,
        "poison" => fn -> Poison.decode(bin) end
      },
      time: 10,
      memory_time: 2,
      parallel: p
    )
  end

  defp benchmarks_decode(p) do
    map =
      %{
        zip: "14006",
        domain: "msn.com",
        ip: "24.213.135.0",
        country: "USA",
        region: "NY",
        query_string: "/en-us/foodanddrink/foodnews/chain-restaurant-french-fries-ranked/ss-AA11UZiC"
      }
    prop = {[{:zip, "14006"}, {:domain, "msn.com"}, {:ip, "24.213.135.0"}, {:country, "USA"}, {:region, "NY"}, {:query_string, "/en-us/foodanddrink/foodnews/chain-restaurant-french-fries-ranked/ss-AA11UZiC"}]}

    IO.puts("parallel: #{p}")

    Benchee.run(
      %{
        "thaos" => fn -> :thoas.encode(map) end,
        "jason" => fn -> Jason.encode(map) end,
        "jiffy" => fn -> :jiffy.encode(prop) end,
        # "simdjsone" => fn -> :simdjson.encode(map) end,
        "poison" => fn -> Poison.encode(map) end
      },
      time: 10,
      memory_time: 2,
      parallel: p
    )
  end
end
