#include <assert.h>
#include <stdio.h>
#include <string.h>

#include <zmk/nemu_link/studio_image.h>
#include <zmk/nemu_link/studio_stream.h>
#include <studio_schema.h>

/* Build against each endpoint's generated studio_schema.h and studio_image.c. */
int main(void) {
    const struct nemu_link_studio_schema schema = {
        .layers = sizeof(studio_stock_order),
        .positions = ZMK_KEYMAP_LEN,
        .layouts = STUDIO_LAYOUT_COUNT,
        .behaviors = studio_behaviors,
        .behavior_count = sizeof(studio_behaviors) / sizeof(studio_behaviors[0]),
    };
    uint8_t descriptor[10 + sizeof(studio_stock_order)] = {'D', 'S', 'C', '1'};
    descriptor[4] = STUDIO_STOCK_LAYOUT;
    descriptor[5] = STUDIO_STOCK_LAYOUT >> 8;
    descriptor[6] = schema.layers;
    descriptor[7] = schema.layers;
    descriptor[8] = schema.positions;
    descriptor[9] = schema.positions >> 8;
    memcpy(descriptor + 10, studio_stock_order, sizeof(studio_stock_order));

    /* This is the first record describe() validates before Studio can sync.
     * Duplicate behavior identities must fail here, not leave BLE switching gated. */
    assert(nemu_link_studio_record_valid(&schema, 0, descriptor, sizeof(descriptor)));

    const uint8_t ble_mode[] = {7, 'n', 'l', '_', 'm', 'o', 'd', 'e',
                               0, 0, 0, 0, 0, 0, 0, 0};
    assert(nemu_link_studio_record_valid(&schema, 2, ble_mode, sizeof(ble_mode)));
    puts("PASS: Studio accepts the endpoint schema and BLE mode binding");
}
