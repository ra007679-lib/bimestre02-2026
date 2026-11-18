/*
	TRABALHO 03 - OPERADORES E FUNÇÕES SQL (PostgreSQL)
	TEMA: Distribuidora de energia elétrica (CEM)
*/


/*
O banco do Trabalho 01 não tem cliente sem e-mail nem cadastro recente. Este INSERT cria um cliente
cadastrado hoje (data_cadastro usa o valor padrão, current_date) e sem e-mail, para que as consultas 2 e 8 retornem resultado.
*/
insert into cliente (nome, cpf_cnpj, tipo_pessoa, email, telefone) values
('Lucas Henrique Martins', '567.890.123-45', 'PF', null, '(31) 97777-1234');


/*
=== BLOCO A - OPERADORES LÓGICOS E DE COMPARAÇÃO ===

Questão 1: a cobrança quer ver as faturas que ainda não foram pagas, mas só as de valor alto (a partir de R$ 200,00), que são as prioritárias.
Sem os parênteses, o AND seria avaliado antes do OR e a condição ficaria:
status = 'VENCIDA' OU (status = 'ABERTA' E valor >= 200). Aí as faturas vencidas de qualquer valor apareceriam no resultado, mesmo abaixo do mínimo.
*/
select f.id_fatura,
       f.mes_referencia,
       f.valor_total,
       f.status
from fatura f
where (f.status = 'VENCIDA' or f.status = 'ABERTA')
  and f.valor_total >= 200;


-- Questão 2: o atendimento quer cadastros de pessoas físicas (não PJ) que não têm e-mail, mas têm telefone, para entrar em contato por ligação.
select c.id_cliente,
       c.nome,
       c.telefone
from cliente c
where c.tipo_pessoa not in ('PJ')
  and c.email is null
  and c.telefone is not null;


-- Questão 3: o financeiro quer as faturas de valor intermediário (entre R$ 150,00 e R$ 700,00) que estão pagas ou abertas, ou seja, que não estão em atraso.
select f.id_fatura,
       f.valor_total,
       f.status
from fatura f
where f.valor_total between 150 and 700
  and f.status in ('PAGA', 'ABERTA')
order by f.valor_total;


/*
=== BLOCO B - BUSCAS TEXTUAIS COM PADRÕES ===

Questão 4a: o atendimento procura um cliente pelo nome sem saber como foi cadastrado.
O ILIKE ignora maiúsculas e minúsculas, então "VALE" encontra "Vale".
*/
select c.id_cliente,
       c.nome
from cliente c
where c.nome ilike '%VALE%';

-- Questão 4b: o atendimento quer só os clientes pessoa física. O CPF tem formato fixo (14 caracteres), então cada _ representa exatamente um caractere.
select c.id_cliente,
       c.nome,
       c.cpf_cnpj
from cliente c
where c.cpf_cnpj like '___.___.___-__';


/*
=== BLOCO C - FUNÇÕES MATEMÁTICAS E DE TEXTO ===

Questão 5: simulação de um reajuste de 7,5% no valor do kWh de cada tarifa.
Mostra o valor atual, o valor reajustado sem tratamento, o arredondado (ROUND) e o cortado (TRUNC).
*/
select t.classe_consumo,
       t.valor_kwh                          as valor_atual,
       t.valor_kwh * 1.075                  as valor_reajustado,
       round(t.valor_kwh * 1.075, 2)        as valor_arredondado,
       trunc(t.valor_kwh * 1.075, 2)        as valor_cortado
from tarifa t
order by t.classe_consumo;

/*
Questão 6a: classifica os clientes em lotes de contato (pares e ímpares) usando o resto da divisão
do código por 2, para dividir a lista entre duas equipes de atendimento.
*/
select c.id_cliente,
       c.nome,
       case when mod(c.id_cliente, 2) = 0 then 'Equipe A (par)'
            else 'Equipe B (ímpar)'
       end                                  as equipe_atendimento
from cliente c
order by c.id_cliente;

-- Questão 6b: sorteia uma unidade consumidora ativa para uma vistoria de qualidade.
select uc.id_uc,
       uc.endereco,
       uc.cidade
from unidade_consumidora uc
where uc.status = 'ATIVA'
order by random()
limit 1;

/*
Questão 7: monta a descrição de contato de cada cliente (CONCAT, com aviso quando não há e-mail),
padroniza o nome em maiúsculas (UPPER) e extrai o domínio do e-mail (SPLIT_PART).
*/
select c.id_cliente,
       concat(c.nome, ' - ', coalesce(c.email, 'e-mail não informado'))  as descricao_contato,
       upper(c.nome)                                                       as nome_padronizado,
       split_part(c.email, '@', 2)                                         as dominio_email
from cliente c
order by c.id_cliente;


/*
=== BLOCO D - FUNÇÕES DE DATA/HORA E FORMATAÇÃO ===

Questão 8: lista os clientes cadastrados nos últimos 30 dias, mostrando o ano, o mês e o dia da semana
do cadastro (0 = domingo) e o primeiro dia do mês (DATE_TRUNC), para o relatório de novos clientes.
*/
select c.nome,
       c.data_cadastro,
       extract(year from c.data_cadastro)                as ano_cadastro,
       extract(month from c.data_cadastro)               as mes_cadastro,
       extract(dow from c.data_cadastro)                 as dia_da_semana,
       date_trunc('month', c.data_cadastro)::date        as inicio_do_mes
from cliente c
where c.data_cadastro >= now() - interval '30 days';

/*
Questão 9: controle de manutenção dos medidores. Calcula há quanto tempo cada um está instalado (AGE)
e projeta a data prevista de troca, considerando 15 anos de vida útil (soma de INTERVAL).
*/
select m.numero_serie,
       m.data_instalacao,
       age(now(), m.data_instalacao)                     as tempo_instalado,
       m.data_instalacao + interval '15 years'           as troca_prevista
from medidor m
order by m.data_instalacao;

/*
Questão 10: relatório gerencial de faturas. Une fatura, unidade consumidora e cliente (INNER JOIN),
formata a data de vencimento no padrão brasileiro, o valor em reais (TO_CHAR) e o código da fatura com zeros à esquerda (LPAD).
*/
select lpad(f.id_fatura::text, 6, '0')                                     as codigo_fatura,
       c.nome                                                               as cliente,
       to_char(f.data_vencimento, 'DD/MM/YYYY')                             as vencimento,
       'R$ ' || to_char(f.valor_total, 'FM999G999G990D00')                  as valor,
       f.status
from fatura f
inner join unidade_consumidora uc on uc.id_uc = f.id_uc
inner join cliente c              on c.id_cliente = uc.id_cliente
order by f.id_fatura;