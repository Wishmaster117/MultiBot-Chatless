-- print(">>> HunterPetFamily.lua exécuté")
MultiBot = MultiBot or {}
MultiBot.PET_FAMILY = {          -- ← fallback enUS
  [1]="Wolf",[2]="Cat",[3]="Spider",[4]="Bear",[5]="Boar",[6]="Crocolisk",[7]="Carrion Bird",
  [8]="Crab",[9]="Gorilla",[11]="Raptor",[12]="Tallstrider",[20]="Scorpid",[21]="Turtle",
  [24]="Bat",[25]="Hyena",[26]="Bird of Prey",[27]="Wind Serpent",[30]="Dragonhawk",
  [31]="Ravager",[32]="Warp Stalker",[33]="Sporebat",[34]="Nether Ray",[35]="Serpent",
  [37]="Moth",[38]="Chimaera",[39]="Devilsaur",[41]="Silithid",[42]="Worm",[43]="Rhino",
  [44]="Wasp",[45]="Core Hound",[46]="Spirit Beast",
}

-- -----------------------------------------------------------------
-- Localisation Table : id =>  translated name
-- -----------------------------------------------------------------
MultiBot.PET_FAMILY_L10N = {
  deDE = {          -- Allemand
    [1]="Wolf",[2]="Katze",[3]="Spinne",[4]="Bär",[5]="Eber",[6]="Krokilisk",
    [7]="Aasvogel",[8]="Krabbe",[9]="Gorilla",[11]="Raptor",[12]="Weitschreiter",
    [20]="Skorpid",[21]="Schildkröte",[24]="Fledermaus",[25]="Hyäne",
    [26]="Raubvogel",[27]="Windnatter",[30]="Drachenfalke",[31]="Verheerer",
    [32]="Sphärenpirscher",[33]="Sporensegler",[34]="Netherrochen",[35]="Schlange",
    [37]="Motte",[38]="Chimäre",[39]="Teufelssaurier",[41]="Silithide",[42]="Wurm",
    [43]="Nashorn",[44]="Wespe",[45]="Kernhund",[46]="Geisterbestie",
  },
  frFR = {          -- Français
    [1]="Loup",[2]="Félin",[3]="Araignée",[4]="Ours",[5]="Sanglier",[6]="Crocilisque",
    [7]="Charognard",[8]="Crabe",[9]="Gorille",[11]="Raptor",[12]="Haut-trotteur",
    [20]="Scorpid",[21]="Tortue",[24]="Chauve-souris",[25]="Hyène",
    [26]="Oiseau de proie",[27]="Serpent des vents",[30]="Faucon-dragon",
    [31]="Ravageur",[32]="Traqueur dimensionnel",[33]="Sporoptère",
    [34]="Raie du Néant",[35]="Serpent",[37]="Phalène",[38]="Chimère",
    [39]="Diablosaurien",[41]="Silithide",[42]="Ver",[43]="Rhinocéros",
    [44]="Guêpe",[45]="Chien du magma",[46]="Bête spirituelle",
  },
  esES = {          -- Espagnol (UE and MX)
    [1]="Lobo",[2]="Felino",[3]="Araña",[4]="Oso",[5]="Jabalí",[6]="Crocolisco",
    [7]="Ave carroñera",[8]="Cangrejo",[9]="Gorila",[11]="Raptor",[12]="Zancudo",
    [20]="Escórpido",[21]="Tortuga",[24]="Murciélago",[25]="Hiena",
    [26]="Ave rapaz",[27]="Serpiente alada",[30]="Halcón dracónico",
    [31]="Devastador",[32]="Acechador vil",[33]="Esporiélago",
    [34]="Raya abisal",[35]="Serpiente",[37]="Polilla",[38]="Quimera",
    [39]="Devilsaurio",[41]="Silítido",[42]="Gusano",[43]="Rinoceronte",
    [44]="Avispa",[45]="Can del Núcleo",[46]="Bestia espíritu",
  },
  ruRU = {          -- Russe
    [1]="Волк",[2]="Кошка",[3]="Паук",[4]="Медведь",[5]="Кабан",[6]="Кроколиск",
    [7]="Падальщик",[8]="Краб",[9]="Горилла",[11]="Ящер",[12]="Долгоног",
    [20]="Скорпид",[21]="Черепаха",[24]="Летучая мышь",[25]="Гиена",
    [26]="Хищная птица",[27]="Крылатый змей",[30]="Дракондор",
    [31]="Опустошитель",[32]="Прыгуана",[33]="Спороскат",
    [34]="Скат Пустоты",[35]="Змея",[37]="Мотылек",[38]="Химера",
    [39]="Дьявозавр",[41]="Силитид",[42]="Червь",[43]="Носорог",
    [44]="Оса",[45]="Гончая Недр",[46]="Дух зверя",
  },
  koKR = {          -- Coréen
    [1]="늑대",[2]="살쾡이",[3]="거미",[4]="곰",[5]="멧돼지",[6]="악어",
    [7]="독수리",[8]="게",[9]="고릴라",[11]="랩터",[12]="타조",
    [20]="전갈",[21]="거북",[24]="박쥐",[25]="하이에나",
    [26]="맹금수",[27]="풍뱀",[30]="용매",[31]="칼날발톱",
    [32]="차원의 추적자",[33]="포자날개",[34]="황천의 가오리",[35]="뱀",
    [37]="나방",[38]="키메라",[39]="악마사우루스",[41]="실리시드",
    [42]="벌레",[43]="코뿔소",[44]="말벌",[45]="용암사냥개",[46]="영혼의 야수",
  },
  zhCN = {          -- Chinois simplifié
    [1]="狼",[2]="猫",[3]="蜘蛛",[4]="熊",[5]="野猪",[6]="鳄鱼",
    [7]="食腐鸟",[8]="螃蟹",[9]="猩猩",[11]="迅猛龙",[12]="长颈陆行鸟",
    [20]="蝎子",[21]="海龟",[24]="蝙蝠",[25]="土狼",
    [26]="猎鹰",[27]="风蛇",[30]="龙鹰",[31]="劫掠者",
    [32]="扭曲猎手",[33]="孢子蝠",[34]="虚空鳐",[35]="蛇",
    [37]="蛾",[38]="双头龙",[39]="魔暴龙",[41]="异种蝎",
    [42]="蠕虫",[43]="犀牛",[44]="黄蜂",[45]="核犬",[46]="灵魂兽",
  },
  zhTW = {          -- Chinois traditionnel
    [1]="狼",[2]="貓",[3]="蜘蛛",[4]="熊",[5]="野豬",[6]="鱷魚",
    [7]="食腐鳥",[8]="螃蟹",[9]="大猩猩",[11]="迅猛龍",[12]="長腳陸行鳥",
    [20]="毒蠍",[21]="海龜",[24]="蝙蝠",[25]="土狼",
    [26]="猛禽",[27]="風蛇",[30]="龍鷹",[31]="劫掠者",
    [32]="扭曲巡者",[33]="孢子蝙蝠",[34]="虛空魟",[35]="蛇",
    [37]="蛾",[38]="奇美拉",[39]="魔暴龍",[41]="異種蟲",
    [42]="蠕蟲",[43]="犀牛",[44]="黃蜂",[45]="熔核犬",[46]="靈魂獸",
  },
}