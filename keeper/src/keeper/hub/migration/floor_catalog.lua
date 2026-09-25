local M = {}

-- Certified legacy floor catalog mapping exact artifact content hashes to their
-- verified runtime floor requirements.
--
-- Authority: FINAL-DESIGN-v4.md §12.1, §16 and ACCEPTANCE-IDS.md (MIG-09, CMP-03).
-- "The target also carries a certified exact-artifact-hash floor catalog for the
-- already installed legacy set so the first boot gate has requirements for every
-- artifact; any hash absent from that catalog refuses boot."
-- "CMP-03: exact-hash certified legacy catalog covers full installed closure;
-- unknown hash never gets a fallback floor; dependency re-resolution repeats preflight."

local function trim(val)
    return string.match(tostring(val or ""), "^%s*(.-)%s*$") or ""
end

local CERTIFIED_HASHES = {
    -- Userspace core modules
    ["c154e2cc11ca94ddd368307aced96cfbbd411a58e74e46339d50b4a9befc1d65"] = {
        name = "userspace/contract", version = "0.4.1", min_runtime = "0.3.40a",
    },
    ["d08b94c08818796409ec65988cad1c7471b5023e9f69cf916a2a926387c2e831"] = {
        name = "userspace/uploads", version = "0.5.20", min_runtime = "0.3.40a",
    },
    ["62d61727c91b2eae3092b4a01c31236cb085ee66a61304f0548d597c5e9951fc"] = {
        name = "userspace/uploads", version = "0.5.16", min_runtime = "0.3.40a",
    },
    ["50d673dd201249b280d1f19a9051e8715e759af5db75b76a4132237020b1c7c9"] = {
        name = "userspace/uploads", version = "0.5.5", min_runtime = "0.3.40a",
    },
    ["09ee988bed624dff05e78a1bf71203cdab46833b91b3c6b062a079c968688a80"] = {
        name = "userspace/users", version = "0.1.5", min_runtime = "0.3.40a",
    },

    -- Wippy core modules
    ["f8b8ed9f8098e254f7b431ca9f5378672bb5deae33122b777d1714092bcca91a"] = {
        name = "wippy/agent", version = "0.4.17", min_runtime = "0.3.40a",
    },
    ["ff47bf040857d520fbf9e576f1b2d8653516d36d340b82e7ecfa8ce1ed2fe9b4"] = {
        name = "wippy/agent", version = "0.4.14", min_runtime = "0.3.40a",
    },
    ["a31e9c64ec482ced0b0095bc0c85b2a69a7b1361c207ab43ffae807da473f6bc"] = {
        name = "wippy/bootloader", version = "0.3.16", min_runtime = "0.3.40a",
    },
    ["aa5e32807eba6a5ea0e5a224069a006288f58605c4542a444f5469caee862c58"] = {
        name = "wippy/bootloader", version = "0.3.14", min_runtime = "0.3.40a",
    },
    ["4f32d32b8a37a7c55b65e72242252eab2d53500591a83dca9787d742a65ff421"] = {
        name = "wippy/bootloader", version = "0.3.13", min_runtime = "0.3.40a",
    },
    ["f0ecb0a9a89c61c516503b86d7d4db564bc597af2218e99c61e1f2dcc6880a72"] = {
        name = "wippy/dataflow", version = "0.7.15", min_runtime = "0.3.40a",
    },
    ["ac10088fa53d09184e25f526aa55c3de975e1d8cbf198d55bd181544ae6d381a"] = {
        name = "wippy/dataflow", version = "0.7.17", min_runtime = "0.3.40a",
    },
    ["718996cb2ae807d60908d0be239d8af20e33adc68f6511647c6ab61bc5455cfe"] = {
        name = "wippy/dataflow", version = "0.5.2", min_runtime = "0.3.40a",
    },
    ["26c48f82861ca423d17fa6fe18a610e29097db27ba44a687c98dcb3da108fb32"] = {
        name = "wippy/llm", version = "0.4.44", min_runtime = "0.3.40a",
    },
    ["414a2e517bc1d27f39acf8936c1d5db75afc8a2ec918318cfcb600c464fbec8c"] = {
        name = "wippy/llm", version = "0.4.46", min_runtime = "0.3.40a",
    },
    ["0fe840b50d9ec7d1f4082dca0027f6009cd539aff5f0fd9234c70673232f6905"] = {
        name = "wippy/llm", version = "0.4.35", min_runtime = "0.3.40a",
    },
    ["e00cad6706bb95f556aeab5318a04e55d3884c027b09f6340fc4e7d69c905a17"] = {
        name = "wippy/migration", version = "0.3.18", min_runtime = "0.3.40a",
    },
    ["55834821cd2832f8582a52e98772810ba3bdfe91d4967262d3d69e6e9c2b2879"] = {
        name = "wippy/migration", version = "0.3.17", min_runtime = "0.3.40a",
    },
    ["9020016afc9de612f5297d38ce99e8500c63a2986077e8b0e560d8636c506627"] = {
        name = "wippy/security", version = "0.4.2", min_runtime = "0.3.40a",
    },
    ["99367f0b7319ae40de517210838e984b0a110c19684e74a3c90b09f575d4783c"] = {
        name = "wippy/security", version = "0.4.1", min_runtime = "0.3.40a",
    },
    ["651bd603d4102702372a4c199bc9f165087a38f6a4ae9579a45bca78710e9df8"] = {
        name = "wippy/session", version = "0.4.2", min_runtime = "0.3.40a",
    },
    ["9473efe8deff669d04dd9b7ef19bda47eb7d7489d228ed78df694406c3909f96"] = {
        name = "wippy/session", version = "0.4.4", min_runtime = "0.3.40a",
    },
    ["9d9b2aca94b6857fea5e47bae014ff582a558a283dae1df5e997fe4fa948e671"] = {
        name = "wippy/session", version = "0.1.31", min_runtime = "0.3.40a",
    },
    ["028180c6044cdd9bbe15330255a4926770e02a291511930264a615f6388824f0"] = {
        name = "wippy/terminal", version = "0.4.5", min_runtime = "0.3.40a",
    },
    ["11fcb6a64895364fa603000afd66e9889b5a711bc881f2b4fe5723cd9772df2a"] = {
        name = "wippy/terminal", version = "0.4.4", min_runtime = "0.3.40a",
    },
    ["37a304cc20aa3005004255e9fda16835a94119db520c0c97e1db044c7844a229"] = {
        name = "wippy/test", version = "0.4.17", min_runtime = "0.3.40a",
    },
    ["cfdbfc0a7cf05fa825d203b80ce92fbd24e03da00e2083efe21ff4266cb44608"] = {
        name = "wippy/test", version = "0.4.13", min_runtime = "0.3.40a",
    },
    ["a25c35b260e8f9c161f372aa8f5e80624af4db233f2b9de4a36d9015342f01fe"] = {
        name = "wippy/views", version = "0.5.10", min_runtime = "0.3.40a",
    },
    ["334151b0a36d1f26482e05c4076aa8f39187871376ac5c86120a5eaf51e91fc3"] = {
        name = "wippy/views", version = "0.5.6", min_runtime = "0.3.40a",
    },
    ["b3c4be305e1ef047cb211a3fddb0e0cbe56ec5d2e678c70134dfa28bbd85c9a8"] = {
        name = "wippy/relay", version = "0.3.14", min_runtime = "0.3.40a",
    },
    ["6d62fefb655ddfab62451edae651d14d62a31db7f29002f7b22ec176fda4798e"] = {
        name = "wippy/usage", version = "0.3.24", min_runtime = "0.3.40a",
    },
    ["8521220405ba7fb388dd434d3064d15dec3a80fbb9e0654b51603365888c721a"] = {
        name = "wippy/facade", version = "0.6.39", min_runtime = "0.3.40a",
    },

    -- Keeper modules
    ["c598a5c5a3b6416415e4f459ab27831af5131819685a6b440024a372352ac585"] = {
        name = "keeper/keeper", version = "0.5.85", min_runtime = "0.3.40a",
    },

    -- Kickside redesign baseline modules
    ["6349517c1302a4a61f453c8ad8a0c039070a10b131df3d33e6b9df6982f3d909"] = {
        name = "kickside/component", version = "0.1.45", min_runtime = "0.3.42a",
    },
    ["b4278cc7250e306ebb1bfdf882c377f3187d44a6525e31075e15463c35157a4c"] = {
        name = "kickside/component", version = "0.1.44", min_runtime = "0.3.42a",
    },
    ["4e22c7609509ebadbec132afee14ee7791b2cac6507e41671f50317d71947f35"] = {
        name = "kickside/agents", version = "0.1.42", min_runtime = "0.3.40a",
    },
    ["730cccefeb76cded9ca93c376f456503fa83c74460cd3bf05e8d8a7d25d6e209"] = {
        name = "kickside/automation", version = "0.1.103", min_runtime = "0.3.40a",
    },
    ["a1dc277e1b486f9d87a4036479e9052dba8bc54b36c72daecc03f37ceef0ef2e"] = {
        name = "kickside/blocks", version = "0.1.24", min_runtime = "0.3.40a",
    },
    ["d62323244b929172bd268ffd4fe1a8fff7ed290b46fa067dab43b14fb4086887"] = {
        name = "kickside/channel", version = "0.1.40", min_runtime = "0.3.40a",
    },
    ["a5cdfffc6eb0d039f666ab8e7fd19d895f9f0a8ce199124e8f3983ae8bbec23b"] = {
        name = "kickside/connection", version = "0.1.37", min_runtime = "0.3.40a",
    },
    ["3cd811910c9aaaf8cd0bfe1d63d0092072a9e40a8aff787aed0d37cb1f9c0967"] = {
        name = "kickside/contract", version = "0.1.34", min_runtime = "0.3.40a",
    },
    ["aea3900372b7ef51269e8e8be17e3c67c34ccce9a464a5a8738545def408eea9"] = {
        name = "kickside/core", version = "0.1.100", min_runtime = "0.3.40a",
    },
    ["a44798957352b78693338169dae63e6fb5bda6146376ca8118ff0548f3e2f0b2"] = {
        name = "kickside/cron", version = "0.1.37", min_runtime = "0.3.40a",
    },
    ["9214fa1050e1c43262cbe32bb190070914d6ac16bea2354801ed8fe44f9d7201"] = {
        name = "kickside/dashboard", version = "0.1.12", min_runtime = "0.3.40a",
    },
    ["3782a4ecaa295e61100d95f6d4966ebf987874967ec9a18a207415f341854297"] = {
        name = "kickside/doc2md", version = "0.8.7", min_runtime = "0.3.40a",
    },
    ["1ed75942542a6ced2b4c6ea54832b0ec112734c86da020107308ce54fb1ed4f6"] = {
        name = "kickside/hub", version = "0.1.49", min_runtime = "0.3.40a",
    },
    ["a6d973e1131ddf00e5961680c05657838f28862c62f53e58a7ebd8d176fb2795"] = {
        name = "kickside/identity", version = "0.1.26", min_runtime = "0.3.40a",
    },
    ["0e6299ba86fc6cd5ecbdf70e090b2022efc8fa078290e55f5325bbd9101bb60d"] = {
        name = "kickside/inbox", version = "0.1.46", min_runtime = "0.3.40a",
    },
    ["452238df8686f6c5593e984c32c1b462c12aea5e7e20189e5d8b36c7f6f4c796"] = {
        name = "kickside/jobs", version = "0.1.29", min_runtime = "0.3.40a",
    },
    ["9899a20fd5ff7cef819febb494adfd4a60615f7878cc2a13342d2bb0a998a0e7"] = {
        name = "kickside/mcp-client", version = "0.1.4", min_runtime = "0.3.40a",
    },
    ["519c7966bbde507594cb63d705c629689c3c4959af084bf1c4bd017debb18a96"] = {
        name = "kickside/models", version = "0.1.51", min_runtime = "0.3.40a",
    },
    ["79dfe2bf0f75abfda96e5eb9d3bc4da211ff00062a417c8e0ff103221cfe0ec6"] = {
        name = "kickside/oauth", version = "0.1.23", min_runtime = "0.3.40a",
    },
    ["66c6f822df2b830aa6c3f91c98dd1e2126680046394826d3243b167bf0bebb07"] = {
        name = "kickside/pdf2image", version = "0.7.7", min_runtime = "0.3.40a",
    },
    ["6dc28822901eb5aed19f3fd3d273306767f080602769a7008e8b7908188025b4"] = {
        name = "kickside/realtime", version = "0.1.20", min_runtime = "0.3.40a",
    },
    ["9ef8fbe58b50c431e2c3b908056308d0f015b971003cd5ff74b9d373adb97473"] = {
        name = "kickside/renderers", version = "0.1.23", min_runtime = "0.3.40a",
    },
    ["b099332519a98de4bd076cba649119af82997d052d3c00ad552d34ecff9b1ae5"] = {
        name = "kickside/security", version = "0.1.31", min_runtime = "0.3.40a",
    },
    ["b480a25d41b148a6713c9765ac531ebf33b8cf170dfaca0a28dadebf7c0f9085"] = {
        name = "kickside/sessions", version = "0.1.27", min_runtime = "0.3.40a",
    },
    ["301409fa50e6b705b6dd8cb2c219974f449736315d6f77a50c175288290e6a53"] = {
        name = "kickside/settings", version = "0.1.34", min_runtime = "0.3.40a",
    },
    ["acc1a935602a186cd46b964a013095fdba655e7f4c5c39c688c335dec780b3b2"] = {
        name = "kickside/sso", version = "0.1.24", min_runtime = "0.3.40a",
    },
    ["121a86a1ab5f2858eb15ec47d38d9d7794d68a74a2b1c846cd411abf22050cb5"] = {
        name = "kickside/sso-google", version = "0.1.8", min_runtime = "0.3.40a",
    },
    ["05ea0f18dfd25de7ce295facb088660d482c707f8bbc1f7e4f8081fc05cbe14f"] = {
        name = "kickside/sync", version = "0.1.61", min_runtime = "0.3.40a",
    },
    ["88174f5c8a0a720737308e36bd68794cba2897bd92d5b75fce3b8a8033ce0d1c"] = {
        name = "kickside/transform", version = "0.1.30", min_runtime = "0.3.40a",
    },
    ["a85c9f5075b4b04940488a2365ee4692bbdcfabb7cc40554a36b1adc1258f01e"] = {
        name = "kickside/ui", version = "0.1.25", min_runtime = "0.3.40a",
    },
    ["2d55c915ff4e458e9ab9a23afc37f6727dfb78b09b0e6a212eb7b91992ae2a77"] = {
        name = "kickside/uploads", version = "0.1.50", min_runtime = "0.3.40a",
    },
    ["e09cd037fc856583855cf9a252583fd67b89dbacfc56655d23369b1343981766"] = {
        name = "kickside/users", version = "0.1.42", min_runtime = "0.3.40a",
    },
    ["8841a783dbfebbb8b4af4ae7f0799b1131b48b8bd5e05047d5a6ccc397a86b00"] = {
        name = "kickside/widgets", version = "0.1.34", min_runtime = "0.3.40a",
    },
}

function M.lookup(hash)
    local key = trim(hash):gsub("^sha256:", "")
    if key == "" then
        return nil, "artifact hash is required"
    end
    local entry = CERTIFIED_HASHES[key]
    if not entry then
        return nil, "UNKNOWN_HASH: artifact hash '" .. key .. "' not found in certified floor catalog"
    end
    return { name = entry.name, version = entry.version,
        min_runtime = entry.min_runtime }, nil
end

function M.get_floor(artifact)
    if type(artifact) ~= "table" then
        return nil, "artifact must be a table"
    end
    -- 1. If declared in artifact manifest
    local declared = trim(artifact.min_runtime or artifact.min_version)
    if declared ~= "" then
        return declared, nil
    end

    -- 2. Certified catalog lookup by hash
    local hash = trim(artifact.hash)
    if hash ~= "" then
        local entry, err = M.lookup(hash)
        if entry then
            local name = trim(artifact.name or artifact.module)
            local version = trim(artifact.version):gsub("^v", "")
            if name ~= "" and entry.name ~= name then
                return nil, "HASH_MISMATCH: certified hash belongs to " .. entry.name
                    .. ", not " .. name
            end
            if version ~= "" and trim(entry.version):gsub("^v", "") ~= version then
                return nil, "HASH_MISMATCH: certified hash belongs to version " .. entry.version
                    .. ", not " .. version
            end
            return entry.min_runtime, nil
        end
        return nil, err
    end

    -- 3. Artifact has neither declared min_runtime nor certified hash
    local identifier = tostring(artifact.name or artifact.id or artifact.module or "unknown")
    return nil, "UNKNOWN_HASH: artifact '" .. identifier .. "' has no declared min_runtime and no hash"
end

return M
