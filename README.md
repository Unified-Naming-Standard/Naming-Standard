# Unified Naming Standard

<p align="center">
  <img src="images/logo.webp" onload="if (new Date().getMonth() === 3 && new Date().getDate() === 1) { this.src = 'images/logo_april_fools.webp'; }" />
</p>

Unified Naming Standard (short UNS), is a unified scripting API inspire by [UNC](https://github.com/unified-naming-convention/NamingStandard) for our loved developers who put their hard work and alot of their time to reverse engineer roblox games and create the scripts we all know and love 💘

> [!NOTE]
> ### We do not provide any DLL file(s) (yet 👀).
> You would have to make the DLL yourself, we only provide basic information on how to use the functions!

![Consider-Starring](https://img.shields.io/badge/consider%20giving%20this%20repo%20a-%20star%21-FFBF00)

<a href="https://star-history.com/#Unified-Naming-Standard/Naming-Standard&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=Unified-Naming-Standard/Naming-Standard&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=Unified-Naming-Standard/Naming-Standard&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=Unified-Naming-Standard/Naming-Standard&type=Date" />
 </picture>
</a>

---

## Why all of this?
Over the decades, scripting has gotten more and more complex to support as many executors as possible. This is because of many unique naming conventions [all the executors](https://github.com/luau/Executor-API-Docs/blob/master/Full-Executor-List) use.

Consider the following scenario. You want to know if a function belongs to the executor or not. In order for this code to be cross compatiable with all executors code like this is needed:
```lua
local is_executor_closure = is_syn_closure or is_fluxus_closure or is_sentinel_closure or is_krnl_closure or is_proto_closure or is_calamari_closure or is_electron_closure or is_elysian_closure or is_valyse_closure or is_sona_closure or is_oxygen_closure or is_krampus_closure or is_sirhut_closure or is_arceus_closure or is_codex_closure or is_wave_closure
```
This is reality for scripters who want cross compatibilty in their scripts. Scripters shouldn't have to do such laborous work just to attain cross compatability. The UNS seeks to solve this problem using naming conventions everyone agrees upon and follows.

One variant of a script should naturally work on all script executors which have their environment properly fitted to the UNS. 

## How can an executor support UNS?
The UNS provides standards for naming conventions as well as API functionality. The standard is written in markdown on this GitHub. Edits or additions are done through pull requests. Edits and additions are manually approved by the UNS council (aka [Master Oogway](https://discord.com/users/830031741225009203)) and discussed by everyone (everyone meaning [Master Oogway](https://discord.com/users/830031741225009203)).

## Supporting UNC
As a product owner, your support of UNC by following the API will result in a far smoother experience for scripters, as they are able to work on scripts that they can confidently say will work on **most** products. Once you have implemented UNC's API, you can display so by adding the badge to your website, thread or application.

You can find the badge here: ~~In Progress, please be patient. Im not that good at designing 🥴.~~

This will tell people of your alliance in providing scripters with an easier method of engineering scripts that your consumers can enjoy.

NOTICE: If you, as a product owner, support >=80% of the functions, you are allowed to display the badge on your website. This may change in the future so keep an eye out for that!

## Checking your environment

You can run the UNC environment checking script to see how well your executor environment supports the UNC standard. Find the script [here](EnvCheck.luau) or [here.](EnvCheck.luau) The script determines what is missing, and writes the results to the in-built developer console of roblox.

## Contributing
Go [here](CONTRIBUTING.md) for a guide on contributing.