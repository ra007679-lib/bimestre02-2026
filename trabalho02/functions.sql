create or replace function retorna_status_uc(p_uc_id integer)
returns text as $$
declare
    v_nome text;
    v_status text;
begin
    select c.nome, uc.status
    into v_nome, v_status
    from unidade_consumidora uc
    join cliente c on c.id_cliente = uc.id_cliente
    where uc.id_uc = p_uc_id;

    if not found then
        return 'Unidade não encontrada!';
    end if;

    return v_nome || ' - Unidade ' || v_status;
end;
$$ language plpgsql;

select retorna_status_uc(1);
select retorna_status_uc(99);


create or replace function calcula_valor_fatura(p_uc_id integer, p_consumo_kwh numeric)
returns numeric(10,2) as $$
declare
    v_valor_kwh numeric;
begin
    select t.valor_kwh
    into v_valor_kwh
    from unidade_consumidora uc
    join tarifa t on t.id_tarifa = uc.id_tarifa
    where uc.id_uc = p_uc_id;

    return round(coalesce(v_valor_kwh, 0) * p_consumo_kwh, 2);
end;
$$ language plpgsql;

select calcula_valor_fatura(1, 170);
select id_fatura, valor_total, calcula_valor_fatura(id_uc, consumo_kwh) as valor_calculado from fatura;


create or replace function atualiza_faturas_vencidas(p_data_ref date)
returns void as $$
begin
    update fatura
    set status = 'VENCIDA'
    where status = 'ABERTA'
      and data_vencimento < p_data_ref;
end;
$$ language plpgsql;

select atualiza_faturas_vencidas('2026-11-15');
select id_fatura, data_vencimento, status from fatura order by id_fatura;