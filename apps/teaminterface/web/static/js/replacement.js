import jQuery from "jquery"

jQuery(function($){
    if ($("#replacement_ranger_grid").length == 0) return;

    const cset_picker = $("#ranger_challenge_set_id");
    const start_field = $("#ranger_start_round");
    const end_field = $("#ranger_end_round");

    const start_links = $("a[data-start]");
    const end_links = $("a[data-end]");

    start_links.click(function(event){
        event.stopPropagation();
        start_field.val($(this).data("start"));
        round_highlighter.call();
    });

    end_links.click(function(event){
        event.stopPropagation();
        end_field.val($(this).data("end"));
        round_highlighter.call();
    });

    const cset_highlighter = function(event){
        const id = cset_picker.val();
        $("[data-cset]").removeClass("highlit");
        $(`[data-cset=${id}]`).addClass("highlit");
    };

    cset_picker.change(cset_highlighter);
    cset_highlighter();

    const round_highlighter = function(event){
        const start_id = Number(start_field.val());
        const end_id = Number(end_field.val());
        $("[data-round]").removeClass("highlit");
        for(var i = start_id; i <= end_id; i++) {
            $(`[data-round=${i}]`).addClass("highlit");
        }
    };

    start_field.change(round_highlighter);
    end_field.change(round_highlighter);
});
