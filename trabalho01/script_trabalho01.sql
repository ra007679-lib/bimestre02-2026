/*
 	TEMA: Distribuidora de energia elétrica
 	
 	JUSTIFICATIVA DA ESCOLHA DO TEMA:
 	
 	Escolhi uma distribuidora de energia elétrica porque é um serviço
	muito presente e envolve um processo de negócio com várias etapas ligadas entre si:
	o cliente contrata a ligação de uma unidade consumidora, um medidor registra o consumo, 
	o consumo vira fatura e a fatura é paga.
	Ou seja, dá bastante conteúdo para praticar o que foi pedido, como as 7 tabelas relacionadas,
	as Chaves Primárias (PK) e Chaves Estrangeiras (FK), como também as restrições.
	
	CONTEXTUALIZAÇÃO:
	
	A "Companhia de Energia Mineira (CEM)" é uma distribuidora de energia elétrica,
	como por exemplo a "CEMIG", que atende clientes residenciais, comerciais, industriais e rurais no estado de Minas Gerais.
*/

create database energia_cem;

/* TABELA CLIENTE
Guarda quem contrata o serviço (pessoa física ou jurídica).
É a base do cadastro comercial, pois um cliente pode ter várias unidades consumidoras,
por exemplo: uma casa e um comércio no nome da mesma pessoa.
*/
create table cliente (
    id_cliente integer generated always as identity primary key,
    nome varchar(100) not null,
    cpf_cnpj varchar(18) not null unique ,
    tipo_pessoa char(2) not null,
    email varchar(100),
    telefone varchar(15),
    data_cadastro date not null default CURRENT_DATE,
    constraint ck_cliente_tipo_pessoa check (tipo_pessoa in ('PF', 'PJ'))
);


/* TABELA TARIFA
Define quanto custa o kWh para cada classe de consumo (residencial, comercial etc.). 
Existe uma única linha por classe e é esse valor que serve para calcular o valor das faturas.
*/
create table tarifa (
    id_tarifa       integer generated always as identity primary key,
    classe_consumo  varchar(20)  not null unique,
    valor_kwh       numeric(6,4) not null,
    constraint ck_tarifa_classe check (classe_consumo in ('RESIDENCIAL', 'COMERCIAL', 'INDUSTRIAL', 'RURAL', 'PODER_PUBLICO')),
    constraint ck_tarifa_valor check (valor_kwh > 0)
);


/* TABELA: UNIDADE_CONSUMIDORA
Representa o ponto físico onde a energia é entregue (casa, loja, fábrica, sítio). 
É ela que liga o cliente à tarifa cobrada e que recebe medidor e faturas.
*/
create table unidade_consumidora (
    id_uc integer generated always as identity primary key,
    id_cliente integer not null references cliente(id_cliente),
    id_tarifa integer not null references tarifa(id_tarifa),
    endereco varchar(150) not null,
    cidade varchar(60) not null,
    tipo_ligacao varchar(12) not null,
    status varchar(12) not null default 'ATIVA',
    data_ligacao date not null,
    constraint ck_uc_tipo_ligacao check (tipo_ligacao in ('MONOFASICA', 'BIFASICA', 'TRIFASICA')),
    constraint ck_uc_status check (status in ('ATIVA', 'SUSPENSA', 'DESLIGADA'))
);


/* TABELA MEDIDOR
Cadastra os equipamentos que medem o consumo. Um medidor fica instalado em uma unidade consumidora.
Se for trocado, o antigo é marcado como inativo e um novo registro é criado.
*/
create table medidor (
    id_medidor integer generated always as identity primary key,
    id_uc integer not null references unidade_consumidora(id_uc),
    numero_serie varchar(20) not null unique,
    modelo varchar(40) not null,
    data_instalacao date not null,
    ativo boolean not null default true
);


/* TABELA LEITURA
Registra o valor acumulado mostrado pelo medidor em cada data de leitura. 
O consumo do mês é a diferença entre duas leituras seguidas, e é a partir dele que a fatura é calculada.
*/
create table leitura (
    id_leitura integer generated always as identity primary key,
    id_medidor integer not null references medidor(id_medidor),
    data_leitura date not null,
    leitura_kwh numeric(10,2) not null,
    constraint ck_leitura_valor check (leitura_kwh >= 0),
    constraint uq_leitura_medidor_data unique (id_medidor, data_leitura)
);


/* TABELA FATURA
Guarda a cobrança mensal de cada unidade consumidora (mês de referência, consumo, valor e vencimento)
Cada unidade só pode ter uma fatura por mês de referência.
*/
create table fatura (
    id_fatura integer generated always as identity primary key,
    id_uc integer not null references unidade_consumidora(id_uc),
    mes_referencia date not null,
    consumo_kwh numeric(10,2) not null,
    valor_total numeric(10,2) not null,
    data_vencimento date not null,
    status varchar(10) not null default 'ABERTA',
    constraint ck_fatura_consumo check (consumo_kwh >= 0),
    constraint ck_fatura_valor check (valor_total >= 0),
    constraint ck_fatura_status check (status in ('ABERTA', 'PAGA', 'VENCIDA')),
    constraint uq_fatura_uc_mes unique (id_uc, mes_referencia)
);

/* TABELA PAGAMENTO
Registra cada pagamento recebido de uma fatura, com data, valor e forma de pagamento. 
Permite acompanhar a arrecadação e saber quais faturas já foram quitadas.
*/
create table pagamento (
    id_pagamento integer generated always as identity primary key,
    id_fatura integer not null references fatura(id_fatura),
    data_pagamento date not null default current_date,
    valor_pago numeric(10,2) not null,
    forma_pagamento varchar(20) not null,
    constraint ck_pagamento_valor check (valor_pago > 0),
    constraint ck_pagamento_forma check (forma_pagamento in ('PIX', 'BOLETO', 'DEBITO_AUTOMATICO', 'CARTAO'))
);


-- ============================================================================================================

insert into cliente (nome, cpf_cnpj, tipo_pessoa, email, telefone, data_cadastro) values
('Mariana Souza Lima', '123.456.789-09', 'PF', 'mariana.lima@email.com', '(31) 99811-2233', '2019-03-12'),
('Mercadinho Boa Esperança LTDA', '12.345.678/0001-95', 'PJ', 'contato@boaesperanca.com', '(31) 3344-5566', '2018-07-01'),
('Metalúrgica Vale do Aço S/A', '23.456.789/0001-10', 'PJ', 'financeiro@valedoaco.com', '(31) 3822-9000', '2015-11-20'),
('José Antônio Pereira', '234.567.890-12', 'PF', 'jose.pereira@email.com', '(34) 99977-4411', '2020-01-15'),
('Carlos Eduardo Ribeiro', '345.678.901-23', 'PF', 'carlos.ribeiro@email.com', '(32) 98855-3322', '2021-05-30'),
('Prefeitura Municipal de Pedra Azul','18.000.111/0001-77','PJ', 'compras@pedraazul.mg.gov.br', '(33) 3622-1000', '2012-02-10'),
('Fernanda Costa Almeida', '456.789.012-34', 'PF', 'fernanda.almeida@email.com', '(31) 98122-7788', '2022-09-05'),
('Padaria Pão Quente ME', '34.567.890/0001-21', 'PJ', 'padariapaoquente@email.com', '(38) 3221-4545', '2023-04-18');
 
insert into tarifa (classe_consumo, valor_kwh) values
('RESIDENCIAL', 0.9500),
('COMERCIAL', 0.8800),
('INDUSTRIAL', 0.6200),
('RURAL', 0.7000),
('PODER_PUBLICO', 0.8000);
 
insert into unidade_consumidora (id_cliente, id_tarifa, endereco, cidade, tipo_ligacao, status, data_ligacao) values
(1, 1, 'Rua das Acácias, 120', 'Belo Horizonte', 'BIFASICA', 'ATIVA', '2019-03-20'),
(2, 2, 'Av. Amazonas, 4500', 'Contagem', 'TRIFASICA', 'ATIVA', '2018-07-10'),
(3, 3, 'Distrito Industrial, Lote 7', 'Ipatinga', 'TRIFASICA', 'ATIVA', '2015-12-01'),
(4, 4, 'Fazenda Santa Luzia, km 12', 'Uberlândia', 'MONOFASICA', 'ATIVA', '2020-02-01'),
(5, 1, 'Rua Halfeld, 800', 'Juiz de Fora', 'MONOFASICA', 'ATIVA', '2021-06-10'),
(6, 5, 'Praça da Matriz, s/n', 'Pedra Azul', 'TRIFASICA', 'ATIVA', '2012-03-01'),
(7, 1, 'Rua do Comércio, 45', 'Betim', 'BIFASICA', 'SUSPENSA', '2022-09-15'),
(8, 2, 'Av. Brasil, 1010', 'Montes Claros', 'BIFASICA', 'DESLIGADA', '2023-05-02');
 
insert into medidor (id_uc, numero_serie, modelo, data_instalacao, ativo) values
(1, 'MED2019000451', 'Elo 2113 Digital', '2019-03-20', true),
(2, 'MED2018000872', 'Nansen Trifásico', '2018-07-10', true),
(3, 'MED2015001203', 'Landis Industrial', '2015-12-01', true),
(4, 'MED2020000115', 'Elo 2113 Digital', '2020-02-01', true),
(5, 'MED2021000640', 'Nansen Smart', '2021-06-10', true),
(6, 'MED2012000098', 'Landis Industrial', '2012-03-01', true),
(7, 'MED2022000733', 'Elo 2113 Digital', '2022-09-15', true),
(8, 'MED2023000310', 'Nansen Smart', '2023-05-02', false);
 
insert into leitura (id_medidor, data_leitura, leitura_kwh) values
(1, '2026-07-05', 12000.00), (1, '2026-08-05', 12180.00), (1, '2026-09-05', 12350.00),
(2, '2026-07-05', 45200.00), (2, '2026-08-05', 45900.00), (2, '2026-09-05', 46650.00),
(3, '2026-07-05', 310000.00), (3, '2026-08-05', 318500.00), (3, '2026-09-05', 327200.00),
(4, '2026-07-05', 8000.00), (4, '2026-08-05', 8260.00), (4, '2026-09-05', 8590.00),
(5, '2026-07-05', 5400.00), (5, '2026-08-05', 5520.00), (5, '2026-09-05', 5690.00);
 
insert into fatura (id_uc, mes_referencia, consumo_kwh, valor_total, data_vencimento, status) values
(1, '2026-08-01', 180.00, 171.00, '2026-10-10', 'PAGA'),
(2, '2026-08-01', 700.00, 616.00, '2026-10-10', 'PAGA'),
(3, '2026-08-01', 8500.00, 5270.00, '2026-10-10', 'PAGA'),
(4, '2026-08-01', 260.00, 182.00, '2026-10-10', 'VENCIDA'),
(5, '2026-08-01', 120.00, 114.00, '2026-10-10', 'PAGA'),
(1, '2026-09-01', 170.00, 161.50, '2026-11-10', 'PAGA'),
(2, '2026-09-01', 750.00, 660.00, '2026-11-10', 'PAGA'),
(3, '2026-09-01', 8700.00, 5394.00, '2026-11-10', 'PAGA'),
(4, '2026-09-01', 330.00, 231.00, '2026-11-10', 'ABERTA'),
(5, '2026-09-01', 170.00, 161.50, '2026-11-10', 'ABERTA');
 
insert into pagamento (id_fatura, data_pagamento, valor_pago, forma_pagamento) values
(1, '2026-10-08', 171.00, 'PIX'),
(2, '2026-10-09', 616.00, 'DEBITO_AUTOMATICO'),
(3, '2026-10-05', 5270.00, 'BOLETO'),
(5, '2026-10-10', 114.00, 'PIX'),
(6, '2026-10-30', 161.50, 'CARTAO'),
(7, '2026-11-02', 660.00, 'DEBITO_AUTOMATICO'),
(8, '2026-11-03', 5394.00, 'BOLETO');


-- ============================================================================================================

-- cada unidade consumidora com o nome do cliente, a cidade e o valor do kWh cobrado
select c.nome as cliente,
		uc.id_uc,
		uc.cidade,
		t.classe_consumo,
		t.valor_kwh
from unidade_consumidora uc
join cliente c on c.id_cliente = uc.id_cliente
join tarifa t on t.id_tarifa = uc.id_tarifa
order by c.nome;

-- quantidade de faturas, consumo total e valor faturado
select t.classe_consumo,
		count(f.id_fatura) as qtd_faturas,
		sum(f.consumo_kwh) as consumo_total_kwh,
		sum(f.valor_total) as valor_faturado
from fatura f
join unidade_consumidora uc on uc.id_uc = f.id_uc
join tarifa t on t.id_tarifa = uc.id_tarifa
group by t.classe_consumo
order by valor_faturado desc;

-- faturas vencidas, com o contato do cliente (para a cobrança)
select c.nome,
		c.telefone,
		f.mes_referencia,
		f.valor_total,
		f.data_vencimento
from fatura f
join unidade_consumidora uc on uc.id_uc = f.id_uc
join cliente c on c.id_cliente = uc.id_cliente
where f.status = 'VENCIDA';

-- clientes com mais de R$ 500,00 faturados no total
select c.nome,
		count(f.id_fatura) as qtd_faturas,
		sum(f.valor_total) as total_faturado
from cliente c
join unidade_consumidora uc on uc.id_cliente = c.id_cliente
join fatura f on f.id_uc = uc.id_uc
group by c.nome
having sum(f.valor_total) > 500
order by total_faturado desc;

-- valor faturado x arrecadado por mês de referência
select to_char(f.mes_referencia, 'MM/YYYY') as mes,
		sum(f.valor_total) as faturado,
		coalesce(sum(p.valor_pago), 0) as arrecadado,
		sum(f.valor_total) - coalesce(sum(p.valor_pago), 0) as em_aberto
from fatura f
left join pagamento p on p.id_fatura = f.id_fatura
group by f.mes_referencia
order by f.mes_referencia;