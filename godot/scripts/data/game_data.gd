class_name GameData
extends RefCounted

## Content registry. Gameplay reads these dictionaries instead of hardcoding
## balance inside the renderer, which keeps future worlds and units additive.

static func worlds() -> Array:
	return [
		{
			"id": 0, "key": "forest", "name": "Floresta Esquecida", "short": "FLORESTA",
			"subtitle": "raízes antigas // vento baixo", "accent": "72e4b3", "secondary": "2b6e6c",
			"coords": "N 01° 24' // E 08° 17'", "boss": "Guardião Corrompido", "weather": "VENTO BAIXO",
			"stages": ["A Clareira do Último Sopro", "Raízes que Observam", "O Rio Sem Reflexo", "Santuário das Cinzas", "O Guardião Desperto"],
			"stage_subtitles": ["primeiro contato", "sinais no musgo", "corrente instável", "o altar perdido", "ameaça de classe ômega"],
			"path": [[-24, 124], [180, 124], [218, 274], [436, 274], [470, 130], [700, 130], [735, 414], [530, 414], [498, 520], [788, 520], [842, 346], [1305, 346]]
		},
		{
			"id": 1, "key": "desert", "name": "Deserto Escarlate", "short": "DESERTO",
			"subtitle": "areia viva // rotas duplas", "accent": "f2bd6b", "secondary": "a75a4b",
			"coords": "S 12° 08' // E 42° 51'", "boss": "Colosso das Dunas", "weather": "TEMPESTADE SECA",
			"stages": ["Portão de Sal", "Cânion dos Corredores", "Dunas Partidas", "Oásis de Ferro", "Colosso das Dunas"],
			"stage_subtitles": ["calor no horizonte", "duas rotas", "blindagem exposta", "água ou aço", "ameaça de classe ômega"],
			"path": [[-24, 464], [165, 464], [218, 165], [430, 165], [478, 464], [675, 464], [722, 168], [982, 168], [1031, 346], [1305, 346]]
		},
		{
			"id": 2, "key": "city", "name": "Cidade Arruinada", "short": "CIDADE",
			"subtitle": "neon partido // sinais hostis", "accent": "8aa8ff", "secondary": "3d5f9f",
			"coords": "N 47° 03' // E 19° 42'", "boss": "Máquina Ômega", "weather": "CHUVA ÁCIDA",
			"stages": ["Terminal 09", "Avenida Zero", "Nó de Rede", "Distrito Suspenso", "Máquina Ômega"],
			"stage_subtitles": ["sinal reacendido", "a cidade respira", "escudos ativos", "ameaça aérea", "ameaça de classe ômega"],
			"path": [[-24, 168], [302, 168], [302, 324], [104, 324], [104, 544], [590, 544], [590, 116], [976, 116], [976, 370], [1305, 370]]
		},
		{
			"id": 3, "key": "frozen", "name": "Terras Congeladas", "short": "GELO",
			"subtitle": "silêncio branco // rotas dinâmicas", "accent": "a6e9ff", "secondary": "4b83ab",
			"coords": "N 68° 14' // E 03° 09'", "boss": "Rei Glacial", "weather": "NEVASCA",
			"stages": ["Margem do Degelo", "Círculo de Gelo", "Passagem Azul", "Palácio Imóvel", "Rei Glacial"],
			"stage_subtitles": ["o frio chegou", "espelhos de gelo", "rota instável", "o trono respira", "ameaça de classe ômega"],
			"path": [[-24, 130], [182, 130], [238, 300], [420, 300], [468, 140], [690, 140], [742, 494], [545, 494], [495, 348], [890, 348], [946, 530], [1305, 530]]
		},
		{
			"id": 4, "key": "void", "name": "Fenda do Vazio", "short": "VAZIO",
			"subtitle": "espaço quebrado // tudo retorna", "accent": "c09dff", "secondary": "684ba5",
			"coords": "— 00° 00' // ∞ 00° 01'", "boss": "Imperador do Vazio", "weather": "GRAVIDADE IRREGULAR",
			"stages": ["Primeira Fissura", "Órbita Morta", "Coro dos Ecos", "A Última Ponte", "Imperador do Vazio"],
			"stage_subtitles": ["o mundo abriu", "sem cima ou baixo", "inimigos lembram", "a ponte final", "ameaça de classe ômega"],
			"path": [[-24, 356], [182, 356], [230, 142], [430, 142], [478, 520], [690, 520], [742, 145], [982, 145], [1035, 356], [1305, 356]]
		}
	]

static func difficulties() -> Dictionary:
	return {
		"normal": {"label": "NORMAL", "hp": 1.0, "speed": 1.0, "count": 1.0, "reward": 1.0, "base_hp": 20},
		"hard": {"label": "DIFÍCIL", "hp": 1.24, "speed": 1.08, "count": 1.12, "reward": 1.22, "base_hp": 16},
		"nightmare": {"label": "PESADELO", "hp": 1.52, "speed": 1.16, "count": 1.24, "reward": 1.52, "base_hp": 12}
	}

static func tower_defs() -> Dictionary:
	return {
		"archer": {"name": "Arqueiro", "role": "ritmo rápido", "color": "f2bd6b", "cost": 85, "damage": 17.0, "cooldown": 0.62, "range": 132.0, "type": "physical", "can_air": true, "projectile": "arrow", "description": "Pressão constante e ótimo alcance.", "branches": [{"id": "marksman", "name": "Atirador Sombrio", "short": "crítico / alcance", "effect": "críticos muito maiores, ataque mais lento."}, {"id": "arrowmaster", "name": "Mestre das Flechas", "short": "salvas / velocidade", "effect": "projéteis múltiplos com menor dano."}]},
		"mage": {"name": "Mago", "role": "dano mágico", "color": "b196ff", "cost": 115, "damage": 27.0, "cooldown": 0.92, "range": 124.0, "type": "magic", "can_air": true, "projectile": "orb", "area": 28.0, "description": "Explosões mágicas atravessam armaduras.", "branches": [{"id": "astral", "name": "Astral", "short": "área / poder", "effect": "explosões maiores e dano mágico."}, {"id": "rift", "name": "Rasgavéu", "short": "controle / alcance", "effect": "aplica lentidão e cobre área maior."}]},
		"cannon": {"name": "Canhão", "role": "impacto em área", "color": "ff8979", "cost": 145, "damage": 62.0, "cooldown": 1.65, "range": 126.0, "type": "physical", "can_air": false, "projectile": "shell", "area": 48.0, "description": "Artilharia lenta, mas devastadora.", "branches": [{"id": "siege", "name": "Cerco", "short": "dano / boss", "effect": "impacto pesado contra alvos resistentes."}, {"id": "shrapnel", "name": "Estilhaço", "short": "área / hordas", "effect": "explosões amplas com menor dano direto."}]},
		"frost": {"name": "Gelo", "role": "controle de rota", "color": "a6e9ff", "cost": 105, "damage": 10.0, "cooldown": 0.72, "range": 116.0, "type": "magic", "can_air": false, "projectile": "shard", "slow": 0.48, "slow_time": 2.6, "area": 18.0, "description": "Diminui o ritmo e compra espaço.", "branches": [{"id": "winter", "name": "Inverno Eterno", "short": "controle / duração", "effect": "lentidão mais forte e duradoura."}, {"id": "rime", "name": "Geada Cortante", "short": "dano / área", "effect": "fragmentos causam mais dano em grupo."}]},
		"volt": {"name": "Raio", "role": "cadeia elétrica", "color": "74c8ff", "cost": 130, "damage": 21.0, "cooldown": 0.86, "range": 118.0, "type": "electric", "can_air": true, "projectile": "chain", "chain": 3, "description": "Salta entre ameaças agrupadas.", "branches": [{"id": "storm", "name": "Tempestade", "short": "cadeia / alcance", "effect": "mais saltos e alcance de corrente."}, {"id": "surge", "name": "Sobrecarga", "short": "dano / crítico", "effect": "correntes menores, porém brutais."}]},
		"sentinel": {"name": "Sentinela", "role": "alcance e crítico", "color": "72e4b3", "cost": 165, "damage": 57.0, "cooldown": 1.72, "range": 216.0, "type": "physical", "can_air": true, "projectile": "bolt", "description": "A torre de precisão que enxerga longe.", "branches": [{"id": "executioner", "name": "Executor", "short": "crítico / elite", "effect": "críticos enormes contra elites e bosses."}, {"id": "oracle", "name": "Oráculo", "short": "alcance / visão", "effect": "alcance superior e alvo mais distante."}]}
	}

static func hero_defs() -> Dictionary:
	return {
		"kael": {"name": "Kael", "role": "guerreiro // controle", "rarity": "RARO", "color": "72e4b3", "sigil": "K", "hp": 145.0, "damage": 24.0, "cooldown": 0.62, "range": 76.0, "speed": 122.0, "ultimate": "Impacto do Titã", "skills": [{"name": "Corte Circular", "short": "CORTE", "cooldown": 8.0, "desc": "Dano em área ao redor de Kael."}, {"name": "Provocação", "short": "PROVOCAÇÃO", "cooldown": 13.0, "desc": "Atrai e desacelera inimigos próximos."}, {"name": "Investida", "short": "INVESTIDA", "cooldown": 10.0, "desc": "Avança até o inimigo mais perigoso."}]},
		"lyra": {"name": "Lyra", "role": "arqueira // precisão", "rarity": "RARO", "color": "f2bd6b", "sigil": "L", "hp": 95.0, "damage": 29.0, "cooldown": 0.54, "range": 170.0, "speed": 136.0, "ultimate": "Tempestade Celestial", "skills": [{"name": "Disparo Perfurante", "short": "PERFURA", "cooldown": 7.0, "desc": "Atravessa uma linha de inimigos."}, {"name": "Chuva de Flechas", "short": "CHUVA", "cooldown": 11.0, "desc": "Flechas caem sobre uma área."}, {"name": "Passo Fantasma", "short": "FANTASMA", "cooldown": 12.0, "desc": "Reposiciona Lyra e concede invulnerabilidade."}]},
		"orion": {"name": "Orion", "role": "mago // contenção", "rarity": "ÉPICO", "color": "b196ff", "sigil": "O", "hp": 108.0, "damage": 38.0, "cooldown": 0.9, "range": 150.0, "speed": 105.0, "ultimate": "Colapso Arcano", "skills": [{"name": "Bola Arcana", "short": "ARCANA", "cooldown": 6.0, "desc": "Projétil mágico que explode."}, {"name": "Prisão Temporal", "short": "PRISÃO", "cooldown": 14.0, "desc": "Congela inimigos em uma área."}, {"name": "Explosão Mística", "short": "MÍSTICA", "cooldown": 10.0, "desc": "Dano mágico ampliado contra blindados."}]},
		"volt": {"name": "Volt", "role": "condutor // cadeia", "rarity": "ÉPICO", "color": "74c8ff", "sigil": "V", "hp": 112.0, "damage": 26.0, "cooldown": 0.72, "range": 132.0, "speed": 118.0, "ultimate": "Julgamento da Tempestade", "skills": [{"name": "Descarga", "short": "DESCARGA", "cooldown": 5.0, "desc": "Raio salta entre inimigos próximos."}, {"name": "Campo Elétrico", "short": "CAMPO", "cooldown": 13.0, "desc": "Zona que atordoa e causa dano."}, {"name": "Teleporte Elétrico", "short": "SALTO", "cooldown": 9.0, "desc": "Salta para a melhor posição do caminho."}]},
		"nyx": {"name": "Nyx", "role": "assassina // crítico", "rarity": "LENDÁRIO", "color": "ff8eb1", "sigil": "N", "hp": 88.0, "damage": 58.0, "cooldown": 1.05, "range": 110.0, "speed": 166.0, "ultimate": "Mil Cortes", "skills": [{"name": "Ataque das Sombras", "short": "SOMBRAS", "cooldown": 6.0, "desc": "Golpe crítico no inimigo mais avançado."}, {"name": "Clone", "short": "CLONE", "cooldown": 15.0, "desc": "Cria um eco que golpeia por alguns segundos."}, {"name": "Invisibilidade", "short": "INVISÍVEL", "cooldown": 12.0, "desc": "Nyx não pode ser atingida por um instante."}]}
	}

static func enemy_defs() -> Dictionary:
	return {
		"basic": {"name": "Batedor", "hp": 72.0, "speed": 67.0, "reward": 9, "leak": 1, "radius": 11.0, "color": "d6e0ef", "armor": 0.0, "magic_resist": 0.0, "role": "equilibrado"},
		"runner": {"name": "Corredor", "hp": 45.0, "speed": 124.0, "reward": 10, "leak": 1, "radius": 9.0, "color": "f2bd6b", "armor": 0.0, "magic_resist": 0.0, "role": "velocidade"},
		"tank": {"name": "Tanque", "hp": 390.0, "speed": 37.0, "reward": 22, "leak": 3, "radius": 17.0, "color": "ff8979", "armor": 0.25, "magic_resist": 0.0, "role": "resistência"},
		"armored": {"name": "Blindado", "hp": 155.0, "speed": 52.0, "reward": 16, "leak": 2, "radius": 13.0, "color": "9caac3", "armor": 0.58, "magic_resist": 0.12, "role": "armadura física"},
		"shielded": {"name": "Escudeiro", "hp": 122.0, "speed": 57.0, "reward": 18, "leak": 2, "radius": 13.0, "color": "74c8ff", "armor": 0.1, "magic_resist": 0.0, "shield": 95.0, "role": "escudo temporário"},
		"flying": {"name": "Voador", "hp": 94.0, "speed": 89.0, "reward": 17, "leak": 2, "radius": 12.0, "color": "b196ff", "armor": 0.0, "magic_resist": 0.0, "flying": true, "role": "ameaça aérea"},
		"healer": {"name": "Curandeiro", "hp": 118.0, "speed": 48.0, "reward": 21, "leak": 2, "radius": 12.0, "color": "72e4b3", "armor": 0.05, "magic_resist": 0.0, "healer": true, "role": "cura aliados"},
		"saboteur": {"name": "Sabotador", "hp": 102.0, "speed": 72.0, "reward": 23, "leak": 2, "radius": 12.0, "color": "ff8eb1", "armor": 0.0, "magic_resist": 0.0, "saboteur": true, "role": "desativa torres"},
		"summoner": {"name": "Invocador", "hp": 184.0, "speed": 43.0, "reward": 27, "leak": 3, "radius": 14.0, "color": "c09dff", "armor": 0.1, "magic_resist": 0.0, "summoner": true, "role": "invoca lacaios"},
		"teleporter": {"name": "Teleportador", "hp": 138.0, "speed": 62.0, "reward": 25, "leak": 3, "radius": 13.0, "color": "8aa8ff", "armor": 0.0, "magic_resist": 0.0, "teleporter": true, "role": "salto de rota"}
	}

static func boss_defs() -> Array:
	return [
		{"key": "forest", "name": "Guardião Corrompido", "color": "72e4b3", "hp": 1500.0, "speed": 30.0, "phases": ["raízes hostis", "coração exposto", "floresta em fúria", "último sopro"]},
		{"key": "desert", "name": "Colosso das Dunas", "color": "f2bd6b", "hp": 2300.0, "speed": 26.0, "phases": ["passos pesados", "soldados da areia", "tempestade escarlate", "marcha final"]},
		{"key": "city", "name": "Máquina Ômega", "color": "8aa8ff", "hp": 2800.0, "speed": 31.0, "phases": ["sistema acordado", "escudos ativos", "pulso EMP", "protocolo terminal"]},
		{"key": "frozen", "name": "Rei Glacial", "color": "a6e9ff", "hp": 3200.0, "speed": 25.0, "phases": ["trono imóvel", "geada viva", "inverno total", "coração de gelo"]},
		{"key": "void", "name": "Imperador do Vazio", "color": "c09dff", "hp": 4200.0, "speed": 34.0, "phases": ["a fenda olha", "ecos sem fim", "gravidade partida", "fim do mapa"]}
	]

static func missions() -> Array:
	return [
		{"id": "kills-500", "title": "Limpeza de perímetro", "desc": "Elimine 500 inimigos em qualquer setor.", "stat": "kills", "target": 500, "gold": 350, "crystals": 1},
		{"id": "skills-20", "title": "Mão no protocolo", "desc": "Use 20 habilidades de herói ou globais.", "stat": "abilities", "target": 20, "gold": 220, "crystals": 1},
		{"id": "boss-3", "title": "Caçador de gigantes", "desc": "Derrote 3 chefes da fronteira.", "stat": "bosses", "target": 3, "gold": 500, "crystals": 3},
		{"id": "untouched", "title": "Linha intocável", "desc": "Vença uma fase sem perder vida do núcleo.", "stat": "perfect_wins", "target": 1, "gold": 300, "crystals": 2},
		{"id": "lightning-100", "title": "Tempestade perfeita", "desc": "Elimine 100 inimigos com Raio ou Volt.", "stat": "lightning_kills", "target": 100, "gold": 420, "crystals": 2}
	]

static func achievements() -> Array:
	return [
		{"id": "first-defense", "title": "Primeira Defesa", "desc": "Conclua o primeiro setor da fronteira.", "stat": "wins", "target": 1},
		{"id": "strategist", "title": "Mestre Estrategista", "desc": "Construa todos os seis tipos de torre.", "stat": "tower_types", "target": 6},
		{"id": "untouchable", "title": "Intocável", "desc": "Vença uma fase sem perder vida.", "stat": "perfect_wins", "target": 1},
		{"id": "giant-hunter", "title": "Caçador de Gigantes", "desc": "Derrote seu primeiro boss.", "stat": "bosses", "target": 1},
		{"id": "storm-perfect", "title": "Tempestade Perfeita", "desc": "Elimine 100 inimigos com eletricidade.", "stat": "lightning_kills", "target": 100}
	]

static func shop_items() -> Array:
	return [
		{"id": "hero-orion", "category": "heroes", "kind": "hero", "target": "orion", "title": "Orion", "color": "b196ff", "sigil": "O", "rarity": "ÉPICO", "price": 8, "currency": "crystals", "meta": ["controle", "mágico"], "desc": "Prende o tempo e transforma armadura em fraqueza."},
		{"id": "hero-volt", "category": "heroes", "kind": "hero", "target": "volt", "title": "Volt", "color": "74c8ff", "sigil": "V", "rarity": "ÉPICO", "price": 12, "currency": "crystals", "meta": ["cadeia", "aéreo"], "desc": "O condutor ideal para ondas que chegam agrupadas."},
		{"id": "hero-nyx", "category": "heroes", "kind": "hero", "target": "nyx", "title": "Nyx", "color": "ff8eb1", "sigil": "N", "rarity": "LENDÁRIO", "price": 1500, "currency": "gold", "meta": ["crítico", "móvel"], "desc": "Uma lâmina viva. Risco alto, janela de dano absurda."},
		{"id": "upgrade-archer", "category": "upgrades", "kind": "research", "target": "archer", "title": "Cordas de Aether", "color": "f2bd6b", "sigil": "A", "rarity": "RARO", "price": 420, "currency": "gold", "meta": ["arqueiro", "+8% dano"], "desc": "Reforça a primeira linha de artilharia."},
		{"id": "upgrade-core", "category": "upgrades", "kind": "core", "target": "core", "title": "Placa do Núcleo", "color": "72e4b3", "sigil": "N", "rarity": "ÉPICO", "price": 6, "currency": "crystals", "meta": ["base", "+2 vida"], "desc": "Duas camadas extras de luz para quando uma rota falhar."},
		{"id": "skin-dusk", "category": "skins", "kind": "skin", "target": "dusk", "title": "Paleta Crepuscular", "color": "c09dff", "sigil": "D", "rarity": "RARO", "price": 600, "currency": "gold", "meta": ["visual", "campo"], "desc": "Uma leitura noturna para os sinais e projéteis."},
		{"id": "skin-ember", "category": "cosmetics", "kind": "skin", "target": "ember", "title": "Brasa de Vigília", "color": "ff8979", "sigil": "B", "rarity": "ÉPICO", "price": 4, "currency": "crystals", "meta": ["visual", "torres"], "desc": "Uma assinatura quente, sem perder legibilidade."},
		{"id": "effect-rift", "category": "effects", "kind": "effect", "target": "rift", "title": "Rastro da Fenda", "color": "c09dff", "sigil": "R", "rarity": "ÉPICO", "price": 5, "currency": "crystals", "meta": ["impacto", "teleporte"], "desc": "Projéteis deixam um rastro curto de gravidade quebrada."},
		{"id": "effect-bloom", "category": "effects", "kind": "effect", "target": "bloom", "title": "Pólen Luminal", "color": "72e4b3", "sigil": "P", "rarity": "RARO", "price": 480, "currency": "gold", "meta": ["impacto", "cura"], "desc": "Uma assinatura suave para curas e recompensas."}
	]
