return {
    -- background image
    bg = 'level0', -- background image

    -- obstacles
    chains = { -- list of x,y coords
        {950, 525, 2950, 525, 2950, 1650, 950, 1650}, -- terrain limits
    },
    polygons = {},
    rectangles = { -- x1,y1, x2,y2
        {950, 930, 1021, 1240},
        {950, 930, 1076, 992},
        {1015, 1175, 1075, 1240},

        {2872, 930, 2955, 1240},
        {2817, 938, 2900, 992},
        {2817, 1175, 2900, 1240},
    },
    -- goals position
    goals = {
        {1000, 992, 1075, 1175},
        {2817, 992, 2900, 1175},
    }
}
