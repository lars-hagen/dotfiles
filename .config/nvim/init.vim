call plug#begin()
" File explorer
" Plug 'preservim/nerdtree'
" Treesitter for better syntax highlighting
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
" Git wrapper
Plug 'tpope/vim-fugitive'
" Git changes in sidebar
Plug 'airblade/vim-gitgutter'

" Fuzzy finder
Plug 'nvim-telescope/telescope.nvim'
" File icons
Plug 'nvim-tree/nvim-web-devicons'
" Status line
Plug 'nvim-lualine/lualine.nvim'
" Starship status line
" Plug 'linrongbin16/starship.nvim'
" Buffer line (tabs)
Plug 'akinsho/bufferline.nvim'
" Auto pairs for brackets
Plug 'windwp/nvim-autopairs'

" Dependencies for avante.nvim
Plug 'stevearc/dressing.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'MunifTanjim/nui.nvim'

" Optional but recommended dependencies
Plug 'hrsh7th/nvim-cmp'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'HakonHarnes/img-clip.nvim'
Plug 'zbirenbaum/copilot.lua'
Plug 'MeanderingProgrammer/render-markdown.nvim'

" Avante.nvim itself
Plug 'yetone/avante.nvim', { 'branch': 'main', 'do': 'make' }

" Key binding helper
Plug 'folke/which-key.nvim'

" Add NvimTree (you already have nvim-web-devicons)
Plug 'nvim-tree/nvim-tree.lua'

" Add these plugins
Plug 'sindrets/diffview.nvim'      " Git diff viewer
Plug 'lewis6991/gitsigns.nvim'     " Git signs in gutter
Plug 'nvim-lua/plenary.nvim'       " Required dependency

call plug#end()

" Treesitter configuration
lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "lua", "vim", "vimdoc", "javascript", "python" },
  highlight = {
    enable = true,
  },
}
EOF

tnoremap <C-q> <C-\><C-n>

" Split window and open terminal at the bottom
command! Aterm botright split term://zsh | startinsert

" Remove background colors for terminal
highlight Normal ctermbg=NONE guibg=NONE
highlight NonText ctermbg=NONE guibg=NONE
highlight LineNr ctermbg=NONE guibg=NONE
highlight SignColumn ctermbg=NONE guibg=NONE
highlight EndOfBuffer ctermbg=NONE guibg=NONE
highlight VertSplit ctermbg=NONE guibg=NONE

" Make status line brighter with light grey background
" highlight StatusLine cterm=NONE ctermfg=white ctermbg=240 gui=NONE guifg=white guibg=#585858

" Split navigation shortcuts
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" Recommended Neovim option for Avante
set laststatus=3

" Set leader key to Space
let mapleader = " "

" Basic editor config
set number relativenumber  " Show relative line numbers
set mouse=a               " Enable mouse support
set expandtab            " Use spaces instead of tabs
set tabstop=4           " Tab width
set shiftwidth=4        " Indent width
set smartindent         " Smart indenting
set hidden              " Allow switching buffers without saving
set termguicolors       " Enable true colors
set cursorline          " Highlight current line
set clipboard+=unnamedplus  " Use system clipboard

" Clipboard mappings (Space is leader key)
vnoremap <leader>c "+y
nnoremap <leader>v "+p
vnoremap <leader>v "+p

" Buffer navigation
nnoremap <Leader>bn :bnext<CR>
nnoremap <Leader>bp :bprevious<CR>
nnoremap <Leader>bd :bdelete<CR>

" Telescope mappings
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" Avante setup
lua << EOF
-- Configure additional plugins
require('lualine').setup({
    options = {
        theme = 'auto',
        component_separators = { left = '', right = ''},
        section_separators = { left = '', right = ''},
        globalstatus = true,
    },
    sections = {
        lualine_a = {'mode'},
        lualine_b = {
            {'branch'},
            {'diff'},
            {'diagnostics'}
        },
        lualine_c = {{'filename', path = 1}},
        lualine_x = {
            function() return '☁️  ' .. (vim.env.AWS_PROFILE or '') end,
            'filetype',
            'encoding'
        },
        lualine_y = {'progress'},
        lualine_z = {'location'}
    }
})
require('bufferline').setup()
require('nvim-autopairs').setup()

-- Make sure to load avante_lib first
require('avante_lib').load()

-- Then setup with full configuration
require('avante').setup({
    provider = "claude",
    behaviour = {
        auto_set_highlight_group = true,
        auto_set_keymaps = true
    },
    windows = {
        position = "right",
        width = 30
    },
    -- Add repo_map configuration
    repo_map = {
        enabled = true
    }
})
EOF

" Which Key setup with organized bindings
lua << EOF
local wk = require("which-key")
wk.setup()

wk.add({
    -- Avante AI group
    { "<leader>a", group = "Avante AI" },
    { "<leader>ac", "<cmd>AvanteChat<cr>", desc = "Start Chat" },
    { "<leader>at", "<cmd>AvanteToggle<cr>", desc = "Toggle Avante" },

    -- Buffer group
    { "<leader>b", group = "Buffer" },
    { "<leader>bd", "<cmd>bdelete<cr>", desc = "Delete Buffer" },
    { "<leader>bn", "<cmd>bnext<cr>", desc = "Next Buffer" },
    { "<leader>bp", "<cmd>bprevious<cr>", desc = "Previous Buffer" },

    -- File group
    { "<leader>f", group = "File" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find File" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
    { "<leader>fn", "<cmd>NvimTreeFindFile<cr>", desc = "Find Current File" },
    { "<leader>ft", "<cmd>NvimTreeToggle<cr>", desc = "Toggle File Tree" },

    -- Git group
    { "<leader>g", group = "Git" },
    { "<leader>gc", "<cmd>Git commit<cr>", desc = "Git Commit" },
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Open Diff View" },
    { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "File History" },
    { "<leader>gp", "<cmd>Git push<cr>", desc = "Git Push" },
    { "<leader>gs", "<cmd>Git<cr>", desc = "Git Status" },

    -- Hunk group
    { "<leader>h", group = "Hunk" },
    { "<leader>hR", "<cmd>Gitsigns reset_buffer<cr>", desc = "Reset Buffer" },
    { "<leader>hS", "<cmd>Gitsigns stage_buffer<cr>", desc = "Stage Buffer" },
    { "<leader>hb", "<cmd>Gitsigns blame_line<cr>", desc = "Blame Line" },
    { "<leader>hd", "<cmd>Gitsigns diffthis<cr>", desc = "Diff This" },
    { "<leader>hp", "<cmd>Gitsigns preview_hunk<cr>", desc = "Preview Hunk" },
    { "<leader>hr", "<cmd>Gitsigns reset_hunk<cr>", desc = "Reset Hunk" },
    { "<leader>hs", "<cmd>Gitsigns stage_hunk<cr>", desc = "Stage Hunk" },
    { "<leader>hu", "<cmd>Gitsigns undo_stage_hunk<cr>", desc = "Undo Stage Hunk" },

    -- Terminal group
    { "<leader>t", group = "Terminal" },
    { "<leader>tt", "<cmd>Aterm<cr>", desc = "Open Terminal" },

    -- Clipboard mappings
    { "<leader>c", '"+y', desc = "Copy to System Clipboard", mode = { "v" } },
    { "<leader>v", '"+p', desc = "Paste from System Clipboard", mode = { "n", "v" } },
})
EOF

" Remove old NERDTree configuration and add NvimTree setup
lua << EOF
-- disable netrw at the very start
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- NvimTree setup
require("nvim-tree").setup({
    sort = {
        sorter = "case_sensitive",
    },
    view = {
        width = 30,
        relativenumber = true,
    },
    renderer = {
        group_empty = true,
        icons = {
            show = {
                file = true,
                folder = true,
                folder_arrow = true,
                git = true,
            },
        },
    },
    filters = {
        dotfiles = false,  -- show hidden files
    },
    git = {
        enable = true,
    },
    actions = {
        open_file = {
            quit_on_open = false,  -- don't close sidebar when opening a file
            window_picker = {
                enable = true,  -- allows picking which window to open the file in
            },
        },
    },
})

-- Keep your familiar keybindings
vim.keymap.set('n', '<C-n>', ':NvimTreeToggle<CR>', { silent = true })
vim.keymap.set('n', '<C-f>', ':NvimTreeFindFile<CR>', { silent = true })
EOF

lua << EOF
-- Setup Gitsigns
require('gitsigns').setup({
    signs = {
        add          = { text = '│' },
        change       = { text = '│' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '┆' },
    },
    on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        -- Navigation
        vim.keymap.set('n', ']c', function()
            if vim.wo.diff then return ']c' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
        end, {expr=true})

        vim.keymap.set('n', '[c', function()
            if vim.wo.diff then return '[c' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
        end, {expr=true})

        -- Actions
        vim.keymap.set('n', '<leader>hs', gs.stage_hunk)
        vim.keymap.set('n', '<leader>hr', gs.reset_hunk)
        vim.keymap.set('v', '<leader>hs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
        vim.keymap.set('v', '<leader>hr', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
        vim.keymap.set('n', '<leader>hS', gs.stage_buffer)
        vim.keymap.set('n', '<leader>hu', gs.undo_stage_hunk)
        vim.keymap.set('n', '<leader>hR', gs.reset_buffer)
        vim.keymap.set('n', '<leader>hp', gs.preview_hunk)
        vim.keymap.set('n', '<leader>hb', function() gs.blame_line{full=true} end)
        vim.keymap.set('n', '<leader>tb', gs.toggle_current_line_blame)
        vim.keymap.set('n', '<leader>hd', gs.diffthis)
        vim.keymap.set('n', '<leader>hD', function() gs.diffthis('~') end)
    end
})

-- Setup Diffview with explicit keymaps
require('diffview').setup({
    use_icons = true,
    keymaps = {
        view = {
            -- Help menu
            ["?"] = ":h diffview-maps<CR>",
            -- Common operations
            ["<tab>"] = "<CMD>DiffviewToggleFiles<CR>",        -- Toggle file panel
            ["<leader>e"] = "<CMD>DiffviewFocusFiles<CR>",     -- Focus file panel
            ["<leader>b"] = "<CMD>DiffviewToggleFiles<CR>",    -- Toggle file panel
        },
        file_panel = {
            ["?"] = ":h diffview-maps<CR>",                    -- Help menu
            ["j"] = "line_down",                               -- Down one line
            ["k"] = "line_up",                                 -- Up one line
            ["<cr>"] = "select_entry",                         -- Open diff for selected
            ["s"] = "stage_entry",                             -- Stage file
            ["u"] = "unstage_entry",                           -- Unstage file
            ["R"] = "refresh_files",                           -- Refresh files
            ["q"] = "<CMD>DiffviewClose<CR>",                  -- Close Diffview
        },
    },
})

EOF
