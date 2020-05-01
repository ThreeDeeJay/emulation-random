/*
   Grade
   > Ubershader grouping some color related monolithic shaders like color-mangler, vignette, lut_x2, white_point,
   > and the addition of vibrance, black level, corner size, rolled gain, sigmoidal contrast and proper gamma transforms.

   Author: hunterk, Guest, Dr. Venom, Dogway
   License: Public domain
*/

#pragma parameter g_gamma_out "LCD Gamma" 2.20 0.0 3.0 0.05
#pragma parameter g_gamma_in "CRT Gamma" 2.40 0.0 3.0 0.05
#pragma parameter g_gamma_type "CRT Gamma (POW = 0, sRGB = 1)" 1.0 0.0 1.0 1.0
#pragma parameter g_vignette "Vignette Toggle" 1.0 0.0 1.0 1.0
#pragma parameter g_vstr "Vignette Strength" 40.0 0.0 50.0 1.0
#pragma parameter g_vpower "Vignette Power" 0.20 0.0 0.5 0.01
#pragma parameter g_csize "Corner size" 0.0 0.0 0.07 0.01
#pragma parameter g_bsize "Border smoothness" 600.0 100.0 600.0 25.0
#pragma parameter wp_temperature "White Point" 9311.0 1031.0 12047.0 72.0
#pragma parameter g_sat "Saturation" 0.0 -1.0 2.0 0.02
#pragma parameter g_vibr "Dullness/Vibrance" 0.0 -1.0 1.0 0.05
#pragma parameter g_hpfix "Hotspot Fix" 0.0 0.0 1.0 1.00
#pragma parameter g_lum "Brightness" 0.0 -0.5 1.0 0.01
#pragma parameter g_cntrst "Contrast" 0.0 -1.0 1.0 0.05
#pragma parameter g_mid "Contrast Pivot" 0.5 0.0 1.0 0.01
#pragma parameter g_lift "Black Level" 0.0 -0.5 0.5 0.01
#pragma parameter blr "Black-Red Tint" 0.0 0.0 1.0 0.01
#pragma parameter blg "Black-Green Tint" 0.0 0.0 1.0 0.01
#pragma parameter blb "Black-Blue Tint" 0.0 0.0 1.0 0.01
#pragma parameter wlr "White-Red Tint" 1.0 0.0 2.0 0.01
#pragma parameter wlg "White-Green Tint" 1.0 0.0 2.0 0.01
#pragma parameter wlb "White-Blue Tint" 1.0 0.0 2.0 0.01
#pragma parameter rg "Red-Green Tint" 0.0 -1.0 1.0 0.005
#pragma parameter rb "Red-Blue Tint" 0.0 -1.0 1.0 0.005
#pragma parameter gr "Green-Red Tint" 0.0 -1.0 1.0 0.005
#pragma parameter gb "Green-Blue Tint" 0.0 -1.0 1.0 0.005
#pragma parameter br "Blue-Red Tint" 0.0 -1.0 1.0 0.005
#pragma parameter bg "Blue-Green Tint" 0.0 -1.0 1.0 0.005
#pragma parameter LUT_Size1 "LUT Size 1" 16.0 8.0 64.0 16.0
#pragma parameter LUT1_toggle "LUT 1 Toggle" 0.0 0.0 1.0 1.0
#pragma parameter LUT_Size2 "LUT Size 2" 64.0 0.0 64.0 16.0
#pragma parameter LUT2_toggle "LUT 2 Toggle" 0.0 0.0 1.0 1.0


#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying
#define COMPAT_ATTRIBUTE attribute
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
   gl_Position = MVPMatrix * VertexCoord;
   TEX0.xy = TexCoord.xy;
}

#elif defined(FRAGMENT)

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out COMPAT_PRECISION vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
uniform sampler2D SamplerLUT1;
uniform sampler2D SamplerLUT2;
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float g_gamma_out;
uniform COMPAT_PRECISION float g_gamma_in;
uniform COMPAT_PRECISION float g_gamma_type;
uniform COMPAT_PRECISION float g_vignette;
uniform COMPAT_PRECISION float g_vstr;
uniform COMPAT_PRECISION float g_vpower;
uniform COMPAT_PRECISION float g_csize;
uniform COMPAT_PRECISION float g_bsize;
uniform COMPAT_PRECISION float wp_temperature;
uniform COMPAT_PRECISION float g_sat;
uniform COMPAT_PRECISION float g_vibr;
uniform COMPAT_PRECISION float g_hpfix;
uniform COMPAT_PRECISION float g_lum;
uniform COMPAT_PRECISION float g_cntrst;
uniform COMPAT_PRECISION float g_mid;
uniform COMPAT_PRECISION float g_lift;
uniform COMPAT_PRECISION float blr;
uniform COMPAT_PRECISION float blg;
uniform COMPAT_PRECISION float blb;
uniform COMPAT_PRECISION float wlr;
uniform COMPAT_PRECISION float wlg;
uniform COMPAT_PRECISION float wlb;
uniform COMPAT_PRECISION float rg;
uniform COMPAT_PRECISION float rb;
uniform COMPAT_PRECISION float gr;
uniform COMPAT_PRECISION float gb;
uniform COMPAT_PRECISION float br;
uniform COMPAT_PRECISION float bg;
uniform COMPAT_PRECISION float LUT_Size1;
uniform COMPAT_PRECISION float LUT1_toggle;
uniform COMPAT_PRECISION float LUT_Size2;
uniform COMPAT_PRECISION float LUT2_toggle;
#else
#define g_gamma_out 2.20
#define g_gamma_in 2.40
#define g_gamma_type 1.0
#define g_vignette 1.0
#define g_vstr 40.0
#define g_vpower 0.2
#define g_csize 0.0
#define g_bsize 600.0
#define wp_temperature 9311.0
#define g_sat 0.0
#define g_vibr 0.0
#define g_hpfix 0.0
#define g_lum 0.0
#define g_cntrst 0.0
#define g_mid 0.5
#define g_lift 0.0
#define blr 0.0
#define blg 0.0
#define blb 0.0
#define wlr 1.0
#define wlg 1.0
#define wlb 1.0
#define rg 0.0
#define rb 0.0
#define gr 0.0
#define gb 0.0
#define br 0.0
#define bg 0.0
#define LUT_Size1 16.0
#define LUT1_toggle 0.0
#define LUT_Size2 64.0
#define LUT2_toggle 0.0
#endif


// White Point Mapping function
//
// From the first comment post (sRGB primaries and linear light compensated)
//      http://www.zombieprototypes.com/?p=210#comment-4695029660
// Based on the Neil Bartlett's blog update
//      http://www.zombieprototypes.com/?p=210
// Inspired itself by Tanner Helland's work
//      http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/

vec3 wp_adjust(vec3 color){

    float temp = wp_temperature / 100.;
    float k = wp_temperature / 10000.;
    float lk = log(k);

    vec3 wp = vec3(1.);

    // calculate RED
    wp.r = (temp <= 65.) ? 1. : 0.32068362618584273 + (0.19668730877673762 * pow(k - 0.21298613432655075, - 1.5139012907556737)) + (- 0.013883432789258415 * lk);

    // calculate GREEN
    float mg = 1.226916242502167 + (- 1.3109482654223614 * pow(k - 0.44267061967913873, 3.) * exp(- 5.089297600846147 * (k - 0.44267061967913873))) + (0.6453936305542096 * lk);
    float pg = 0.4860175851734596 + (0.1802139719519286 * pow(k - 0.14573069517701578, - 1.397716496795082)) + (- 0.00803698899233844 * lk);
    wp.g = (temp <= 65.5) ? ((temp <= 8.) ? 0. : mg) : pg;

    // calculate BLUE
    wp.b = (temp <= 19.) ? 0. : (temp >= 66.) ? 1. : 1.677499032830161 + (- 0.02313594016938082 * pow(k - 1.1367244820333684, 3.) * exp(- 4.221279555918655 * (k - 1.1367244820333684))) + (1.6550275798913296 * lk);

    // clamp
    wp.rgb = clamp(wp.rgb, vec3(0.), vec3(1.));

    // Linear color input
    return color * wp;
}

vec3 sRGB_to_XYZ(vec3 RGB){

    const mat3x3 m = mat3x3(
    0.4124564, 0.3575761, 0.1804375,
    0.2126729, 0.7151522, 0.0721750,
    0.0193339, 0.1191920, 0.9503041);
    return RGB * m;
}


vec3 XYZtoYxy(vec3 XYZ){

    float XYZrgb = XYZ.r+XYZ.g+XYZ.b;
    float Yxyg = (XYZrgb <= 0.0) ? 0.3805 : XYZ.r / XYZrgb;
    float Yxyb = (XYZrgb <= 0.0) ? 0.3769 : XYZ.g / XYZrgb;
    return vec3(XYZ.g, Yxyg, Yxyb);
}


vec3 XYZ_to_sRGB(vec3 XYZ){

    const mat3x3 m = mat3x3(
    3.2404542, -1.5371385, -0.4985314,
   -0.9692660,  1.8760108,  0.0415560,
    0.0556434, -0.2040259,  1.0572252);
    return XYZ * m;
}


vec3 YxytoXYZ(vec3 Yxy){

    float Xs = Yxy.r * (Yxy.g/Yxy.b);
    float Xsz = (Yxy.r <= 0.0) ? 0.0 : 1.0;
    vec3 XYZ = vec3(Xsz,Xsz,Xsz) * vec3(Xs, Yxy.r, (Xs/Yxy.g)-Xs-Yxy.r);
    return XYZ;
}

//  This shouldn't be necessary but it seems some undefined values can
//  creep in and each GPU vendor handles that differently. This keeps
//  all values within a safe range
vec3 mixfix(vec3 a, vec3 b, float c)
{
    return (a.z < 1.0) ? mix(a, b, c) : a;
}


vec4 mixfix_v4(vec4 a, vec4 b, float c)
{
    return (a.z < 1.0) ? mix(a, b, c) : a;
}


float SatMask(float color_r, float color_g, float color_b)
{
    float max_rgb = max(color_r, max(color_g, color_b));
    float min_rgb = min(color_r, min(color_g, color_b));
    float msk = clamp((max_rgb - min_rgb) / (max_rgb + min_rgb), 0.0, 1.0);
    return msk;
}


float moncurve_f( float color, float gamma, float offs)
{
    // Forward monitor curve
    color = clamp(color, 0.0, 1.0);
    float fs = (( gamma - 1.0) / offs) * pow( offs * gamma / ( ( gamma - 1.0) * ( 1.0 + offs)), gamma);
    float xb = offs / ( gamma - 1.0);

    color = ( color > xb) ? pow( ( color + offs) / ( 1.0 + offs), gamma) : color * fs;
    return color;
}


vec3 moncurve_f_f3( vec3 color, float gamma, float offs)
{
    color.r = moncurve_f( color.r, gamma, offs);
    color.g = moncurve_f( color.g, gamma, offs);
    color.b = moncurve_f( color.b, gamma, offs);
    return color.rgb;
}


float moncurve_r( float color, float gamma, float offs)
{
    // Reverse monitor curve
    color = clamp(color, 0.0, 1.0);
    float yb = pow( offs * gamma / ( ( gamma - 1.0) * ( 1.0 + offs)), gamma);
    float rs = pow( ( gamma - 1.0) / offs, gamma - 1.0) * pow( ( 1.0 + offs) / gamma, gamma);

    color = ( color > yb) ? ( 1.0 + offs) * pow( color, 1.0 / gamma) - offs : color * rs;
    return color;
}


vec3 moncurve_r_f3( vec3 color, float gamma, float offs)
{
    color.r = moncurve_r( color.r, gamma, offs);
    color.g = moncurve_r( color.g, gamma, offs);
    color.b = moncurve_r( color.b, gamma, offs);
    return color.rgb;
}


//  Performs better in gamma encoded space
float contrast_sigmoid(float color, float cont, float pivot){

    cont = pow(cont + 1., 3.);

    float knee = 1. / (1. + exp(cont * pivot));
    float shldr = 1. / (1. + exp(cont * (pivot - 1.)));

    color = (1. / (1. + exp(cont * (pivot - color))) - knee) / (shldr - knee);

    return color;
}


//  Performs better in gamma encoded space
float contrast_sigmoid_inv(float color, float cont, float pivot){

    cont = pow(cont - 1., 3.);

    float knee = 1. / (1. + exp (cont * pivot));
    float shldr = 1. / (1. + exp (cont * (pivot - 1.)));

    color = pivot - log(1. / (color * (shldr - knee) + knee) - 1.) / cont;

    return color;
}


float rolled_gain(float color, float gain){

    float gx = gain + 1.0;
    float ax = (max(0.5 - (gx / 2.0), 0.5));
    float cx = (gx > 0.0) ? (1.0 - gx + (gx / 2.0)) : abs(gx) / 2.0;

    float gain_plus = ((color * gx) > ax) ? (ax + cx * tanh((color * gx - ax) / cx)) : (color * gx);
    float ax_g = 1.0 - abs(gx);
    float gain_minus = (color > ax_g) ? (ax_g + cx * tanh((color - ax_g) / cx)) : color;
    color = (gx > 0.0) ? gain_plus : gain_minus;

    return color;
}

vec4 rolled_gain_v4(vec4 color, float gain){

    color.r = rolled_gain(color.r, gain);
    color.g = rolled_gain(color.g, gain);
    color.b = rolled_gain(color.b, gain);

    return vec4(color.rgb, 1.0);
}


//  Borrowed from cgwg's crt-geom, under GPL
float corner(vec2 coord)
{
    coord *= SourceSize.xy / InputSize.xy;
    coord = (coord - vec2(0.5)) * 1.0 + vec2(0.5);
    coord = min(coord, vec2(1.0)-coord) * vec2(1.0, OutputSize.y/OutputSize.x);
    vec2 cdist = vec2(max(g_csize, max((1.0-smoothstep(100.0,600.0,g_bsize))*0.01,0.002)));
    coord = (cdist - min(coord,cdist));
    float dist = sqrt(dot(coord,coord));
    return clamp((cdist.x-dist)*g_bsize,0.0, 1.0);
}


void main()
{

//  Pure power was crushing blacks (eg. DKC2). You can mimic pow(c, 2.40) by raising the g_gamma_in value to 2.55
    vec3 imgColor = COMPAT_TEXTURE(Source, vTexCoord).rgb;
    imgColor = (g_gamma_type == 1.0) ? moncurve_f_f3(imgColor, g_gamma_in + 0.15, 0.055) : pow(imgColor, vec3(g_gamma_in));


//  Look LUT
    float red = ( imgColor.r * (LUT_Size1 - 1.0) + 0.4999 ) / (LUT_Size1 * LUT_Size1);
    float green = ( imgColor.g * (LUT_Size1 - 1.0) + 0.4999 ) / LUT_Size1;
    float blue1 = (floor( imgColor.b * (LUT_Size1 - 1.0) ) / LUT_Size1) + red;
    float blue2 = (ceil( imgColor.b * (LUT_Size1 - 1.0) ) / LUT_Size1) + red;
    float mixer = clamp(max((imgColor.b - blue1) / (blue2 - blue1), 0.0), 0.0, 32.0);
    vec3 color1 = COMPAT_TEXTURE( SamplerLUT1, vec2( blue1, green )).rgb;
    vec3 color2 = COMPAT_TEXTURE( SamplerLUT1, vec2( blue2, green )).rgb;
    vec3 vcolor = (LUT1_toggle == 0.0) ? imgColor : mixfix(color1, color2, mixer);


//  Saturation agnostic sigmoidal contrast
    vec3 Yxy = XYZtoYxy(sRGB_to_XYZ(vcolor));
    float toGamma = clamp(moncurve_r(Yxy.r, 2.40, 0.055), 0.0, 1.0);
    toGamma = (g_hpfix == 0.0) ? toGamma : ((Yxy.r > 0.5) ? contrast_sigmoid_inv(toGamma, 2.3, 0.5) : toGamma);
    float sigmoid = (g_cntrst > 0.0) ? contrast_sigmoid(toGamma, g_cntrst, g_mid) : contrast_sigmoid_inv(toGamma, g_cntrst, g_mid);
    vec3 contrast = vec3(moncurve_f(sigmoid, 2.40, 0.055), Yxy.g, Yxy.b);
    vec3 XYZsrgb = clamp(XYZ_to_sRGB(YxytoXYZ(contrast)), 0.0, 1.0);
    contrast = (g_cntrst == 0.0) && (g_hpfix == 0.0) ? vcolor : ((g_cntrst != 0.0) || (g_hpfix != 0.0) ? XYZsrgb : vcolor);


//  Vignetting & Black Level
    vec2 vpos = vTexCoord * (TextureSize.xy / InputSize.xy);
    vpos *= 1.0 - vpos.xy;
    float vig = vpos.x * vpos.y * g_vstr;
    vig = min(pow(vig, g_vpower), 1.0);
    contrast *= (g_vignette == 1.0) ? vig : 1.0;

    contrast += (g_lift / 20.0) * (1.0 - contrast);


//  RGB related transforms
    vec4 screen = vec4(max(contrast, 0.0), 1.0);
    float sat = g_sat + 1.0;

                      //  r    g    b  alpha ; alpha does nothing for our purposes
    mat4 color = mat4(  wlr,  rg,  rb, 0.0,  //red tint
                         gr, wlg,  gb, 0.0,  //green tint
                         br,  bg, wlb, 0.0,  //blue tint
                        blr/20., blg/20., blb/20., 0.0); //black tint

    mat4 adjust = mat4((1.0 - sat) * 0.2126 + sat, (1.0 - sat) * 0.2126, (1.0 - sat) * 0.2126, 1.0,
                       (1.0 - sat) * 0.7152, (1.0 - sat) * 0.7152 + sat, (1.0 - sat) * 0.7152, 1.0,
                       (1.0 - sat) * 0.0722, (1.0 - sat) * 0.0722, (1.0 - sat) * 0.0722 + sat, 1.0,
                        0.0, 0.0, 0.0, 1.0);

    screen = clamp(rolled_gain_v4(screen, g_lum * 2.0), 0.0, 1.0);
    screen = color * screen;
    float sat_msk = (g_vibr > 0.0) ? clamp(1.0 - (SatMask(screen.r, screen.g, screen.b) * g_vibr), 0.0, 1.0) : clamp(1.0 - abs(SatMask(screen.r, screen.g, screen.b) - 1.0) * abs(g_vibr), 0.0, 1.0);
    screen = mixfix_v4(screen, adjust * screen, sat_msk);


//  Color Temperature
    vec3 adjusted = wp_adjust(screen.rgb);
    vec3 base_luma = XYZtoYxy(sRGB_to_XYZ(screen.rgb));
    vec3 adjusted_luma = XYZtoYxy(sRGB_to_XYZ(adjusted));
    adjusted = adjusted_luma + (vec3(base_luma.r, 0.0, 0.0) - vec3(adjusted_luma.r, 0.0, 0.0));
    adjusted = clamp(XYZ_to_sRGB(YxytoXYZ(adjusted)), 0.0, 1.0);


//  Technical LUT - if using RGB phosphors, disable this and add through a LUT.glsl at bottom stack
    float red_2 = ( adjusted.r * (LUT_Size2 - 1.0) + 0.4999 ) / (LUT_Size2 * LUT_Size2);
    float green_2 = ( adjusted.g * (LUT_Size2 - 1.0) + 0.4999 ) / LUT_Size2;
    float blue1_2 = (floor( adjusted.b * (LUT_Size2 - 1.0) ) / LUT_Size2) + red_2;
    float blue2_2 = (ceil( adjusted.b * (LUT_Size2 - 1.0) ) / LUT_Size2) + red_2;
    float mixer_2 = clamp(max((adjusted.b - blue1_2) / (blue2_2 - blue1_2), 0.0), 0.0, 32.0);
    vec3 color1_2 = COMPAT_TEXTURE( SamplerLUT2, vec2( blue1_2, green_2 )).rgb;
    vec3 color2_2 = COMPAT_TEXTURE( SamplerLUT2, vec2( blue2_2, green_2 )).rgb;
    vec3 LUT2_output = mixfix(color1_2, color2_2, mixer_2);

    LUT2_output = (LUT2_toggle == 0.0) ? adjusted : LUT2_output;
    LUT2_output = (g_gamma_out == 1.00) ? LUT2_output : moncurve_r_f3(LUT2_output, g_gamma_out + 0.20, 0.055);

    vpos *= (InputSize.xy/TextureSize.xy);
    FragColor = vec4(LUT2_output*corner(vpos), 1.0);
}
#endif
