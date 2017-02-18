return {
    -- background image
    bg = 'level0', -- background image

    -- obstacles
    chains = { -- list of x,y coords
        {59, 40, 1860, 40, 1860, 1040, 59, 1040}, -- terrain limits
    },
    polygons = {},
    rectangles = { -- x1,y1, x2,y2
        {58, 390, 122, 447}, -- gloals obstacles
        {58, 682, 122, 626},
        {1860, 398, 1793, 456},
        {1860, 690, 1793, 634},
    },
    -- goals position
    goals = {
        {72, 448, 122, 625}, -- topleft, bottomright
        {1795, 445, 1844, 633}
    }
}
