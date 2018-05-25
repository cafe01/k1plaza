---
title: <x-blog>
layout: docs
---



# Atributos 

## `name`

* __Obrigatório__
O nome do blog que deseja renderizar. Declarado na seção `widgets` do arquivo app.yml.


    <x-blog name="meublog">
        <!-- template do blog aqui  -->
    </x-blog>


## `limit`

* __Padrão: 10__

Limite de posts a serem exibidos por página. Ideal para exibir os últimos posts.

    <x-blog name="meublog" limit="3">
        <!-- template para o componente "ultimos posts" aqui  -->
    </x-blog>

## `start`

* __Padrão: 0__

Define o primeiro item a ser exibido. Usado para "pular" X posts.

    <!-- começar a exibir a partir do segundo item -->
    <x-blog name="meublog" start="2">
        <!-- template aqui  -->
    </x-blog>


## `render_similar`

* __Apenas em páginas single-post.__

Exibe os posts similares ao que está sendo exibido na página atual. 
Os itens similares são computados com base na similaridade das tags.

## `year` 
Filtra os itens exibidos pelo ano.

## `month` 
Filtra os itens exibidos pelo mes.

## `day` 
Filtra os itens exibidos pelo dia.

## `slug` 
Filtra os itens exibidos pelo slug.

## `category` 
Filtra os itens exibidos pela categoria.

## `tag`
Filtra os itens exibidos pela tag.

## `url-format`
- Default: "year/month/day/permalink"

Define o formato da URL gerada para um post individual.

    <!-- opções válidas: -->
    <x-blog name="meublog" url-format="year/month/day/permalink"> ... </x-blog>
    <x-blog name="meublog" url-format="year/month/permalink"> ... </x-blog>
    <x-blog name="meublog" url-format="year/permalink"> ... </x-blog>
    <x-blog name="meublog" url-format="permalink"> ... </x-blog>

