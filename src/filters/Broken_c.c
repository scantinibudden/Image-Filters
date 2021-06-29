#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "../tp2.h"
#include "../helper/utils.h"

void Broken_c(
    uint8_t *src,
    uint8_t *dst,
    int width,
    int height,
    int src_row_size,
    int dst_row_size)
{
    bgra_t (*src_matrix)[(src_row_size+3)/4] = (bgra_t (*)[(src_row_size+3)/4]) src;
    bgra_t (*dst_matrix)[(dst_row_size+3)/4] = (bgra_t (*)[(dst_row_size+3)/4]) dst;
 

    /*for (int i = 1; i < height - 1; i++) {
        for (int j = 1; j < width - 1; j++) {
            if ((src_matrix[i][j].r == src_matrix[i][j].g) && (src_matrix[i][j].g == src_matrix[i][j].b)){
                dst_matrix[i][j].r = (src_matrix[i][j - 1].r + src_matrix[i][j + 1].r + src_matrix[i - 1][j].r + src_matrix[i + 1][j].r)/4;
                dst_matrix[i][j].g = (src_matrix[i][j - 1].g + src_matrix[i][j + 1].g + src_matrix[i - 1][j].g + src_matrix[i + 1][j].g)/4;
                dst_matrix[i][j].b = (src_matrix[i][j - 1].b + src_matrix[i][j + 1].b + src_matrix[i - 1][j].b + src_matrix[i + 1][j].b)/4;
            }
        }
    }*/

    for (int i = 0; i < height; i++)
    {
        for (int j = 0; j < width; j++)
        {
            dst_matrix[i][j].r = src_matrix[i][j].r;
            dst_matrix[i][j].g = src_matrix[i][j].g;
            dst_matrix[i][j].b = src_matrix[i][j].b;
        }
    }
}
