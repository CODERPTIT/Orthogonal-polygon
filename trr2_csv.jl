# Import các thư viện cần thiết
using Plots
using Random

# Thiết lập seed để tái lập kết quả
Random.seed!(1234)

# Sử dụng backend GR, với fallback nếu cần
try
    gr()
catch
    println("Backend GR không khả dụng, chuyển sang backend mặc định.")
    plotly()
end

"""
    is_right_angle(p1, p2, p3)
Kiểm tra xem góc tại điểm p2 (giữa p1-p2 và p2-p3) có phải là 90 độ không.
"""
function is_right_angle(p1, p2, p3)
    v1 = (p2[1] - p1[1], p2[2] - p1[2])
    v2 = (p3[1] - p2[1], p3[2] - p2[2])
    return v1[1] * v2[1] + v1[2] * v2[2] == 0
end

"""
    generate_fractal_like_path(num_points::Int, step::Int=1)
Tạo đường đi dạng fractal khép kín với `num_points` đỉnh góc 90 độ.

- **Tham số**:
  - `num_points`: Số đỉnh góc 90 độ mong muốn (phải là số chẵn và ≥ 4).
  - `step`: Khoảng cách giữa các đỉnh (mặc định là 1).
- **Trả về**:
  - Danh sách các tọa độ `(x, y)` tạo thành đường đi khép kín.
"""
function generate_fractal_like_path(num_points::Int, step::Int=1)
    if num_points % 2 != 0
        throw(ErrorException("Số đỉnh phải là số chẵn để tạo chu trình khép kín."))
    end
    if num_points < 4
        throw(ErrorException("Số đỉnh phải ít nhất là 4."))
    end

    path = [(0, 0), (1, 0), (1, 1), (0, 1), (0, 0)]
    visited = Set([(0, 0), (1, 0), (1, 1), (0, 1)])
    directions = [(1, 0), (0, 1), (-1, 0), (0, -1)]
    
    # Đếm số đỉnh góc 90 độ hiện tại (hình vuông ban đầu có 4 góc 90 độ)
    right_angle_count = 4

    while right_angle_count < num_points
        idx = rand(1:(length(path)-1))
        p = path[idx]
        q = path[idx + 1]
        dx, dy = q[1] - p[1], q[2] - p[2]

        # Chọn hướng vuông góc với (dx, dy)
        perp_directions = [(dy, -dx), (-dy, dx)]
        shuffle!(perp_directions)
        for (test_dx, test_dy) in [perp_directions; directions]
            r = (p[1] + test_dx * step, p[2] + test_dy * step)
            if r ∉ visited
                s = (r[1] + dx * step, r[2] + dy * step)
                if s ∉ visited
                    # Chèn r và s tạm thời
                    insert!(path, idx + 1, r)
                    insert!(path, idx + 2, s)
                    
                    # Kiểm tra các góc mới
                    new_count = right_angle_count
                    if is_right_angle(p, r, s)
                        new_count += 1
                    end
                    if is_right_angle(r, s, q)
                        new_count += 1
                    end
                    # Kiểm tra ảnh hưởng đến các góc lân cận
                    if idx > 1 && is_right_angle(path[idx-1], p, r)
                        new_count += 1
                    elseif idx > 1 && is_right_angle(path[idx-1], p, q)
                        new_count -= 1
                    end
                    if idx + 4 <= length(path) && is_right_angle(s, q, path[idx+4])
                        new_count += 1
                    elseif idx + 4 <= length(path) && is_right_angle(p, q, path[idx+4])
                        new_count -= 1
                    end

                    if new_count <= num_points
                        push!(visited, r, s)
                        right_angle_count = new_count
                        if right_angle_count == num_points
                            println("✅ Đã đạt $num_points đỉnh góc 90 độ!")
                            return path
                        end
                    else
                        # Hoàn tác
                        deleteat!(path, idx + 1:idx + 2)
                    end
                end
            end
        end
    end
    return path
end

"""
    save_path_to_csv(path, filename::String)
Lưu đường đi vào file CSV.
"""
function save_path_to_csv(path, filename::String)
    try
        open(filename, "w") do io
            write(io, "x,y\n")
            for (x, y) in path
                write(io, "$x,$y\n")
            end
        end
        println("✅ Đã lưu đường đi vào $filename")
    catch e
        println("Lỗi khi lưu file $filename: ", e)
    end
end

"""
    draw_path(path, num_points::Int; title::String="Fractal Đường đi", fill_polygon::Bool=false)
Vẽ đường đi, chỉ tô các đỉnh tạo góc 90 độ, đánh dấu điểm đầu/cuối.
"""
function draw_path(path, num_points::Int; title::String="Fractal Đường đi", fill_polygon::Bool=false)
    x, y = first.(path), last.(path)
    plt = plot(
        x, y;
        linewidth=0.5,
        size=(2000, 2000),  # Giảm kích thước để phù hợp hơn
        color=:black,
        label="",
        aspect_ratio=:equal,
        legend=true,
        title=title,
        titlefontsize=15,
        xlabel="x",
        ylabel="y"
    )

    if fill_polygon
        plot!(x, y; fill=(0, :mediumpurple, 0.3), label="")
    end

    # Xác định và tô các đỉnh tạo góc 90 độ
    right_angle_x = Float64[]
    right_angle_y = Float64[]
    n = length(path)
    for i in 2:(n-1)
        if is_right_angle(path[i-1], path[i], path[i+1])
            push!(right_angle_x, path[i][1])
            push!(right_angle_y, path[i][2])
        end
    end
    if is_right_angle(path[n-1], path[1], path[2])
        push!(right_angle_x, path[1][1])
        push!(right_angle_y, path[1][2])
    end

    scatter!(right_angle_x, right_angle_y;
        markersize=0.5,
        marker=:circle,
        color=:red,
        label="Đỉnh góc 90 độ"
    )

    scatter!([x[1]], [y[1]];
        markersize=5,
        marker=:star5,
        markerstrokecolor=:red,
        markerstrokewidth=0.5,
        label="Bắt đầu/Kết thúc"
    )

    return plt
end

"""
    main()
Chạy chương trình chính: nhập số đỉnh, tạo đường đi, lưu CSV, vẽ và lưu ảnh.
"""
function main()
    try
        println("Nhập số đỉnh góc 90 độ cần đi qua: ")
        input = readline()
        num_points = tryparse(Int, input)
        if isnothing(num_points)
            throw(ErrorException("Vui lòng nhập một số nguyên hợp lệ."))
        end

        println("Đang tạo đường đi với $num_points đỉnh góc 90 độ...")
        total_start_time = time()

        # Tạo đường đi
        start_time = time()
        path = generate_fractal_like_path(num_points)
        gen_time = time() - start_time
        println("Thời gian tạo đường đi: $(round(gen_time, digits=2)) giây")
        println("Tổng số điểm (bao gồm cả không tạo góc 90 độ): $(length(path))")

        # Lưu đường đi vào CSV
        csv_filename = "fractal_$(num_points)_dinh.csv"
        save_path_to_csv(path, csv_filename)

        # Vẽ và lưu hình
        draw_start_time = time()
        plt = draw_path(path, num_points; fill_polygon=true)
        try
            savefig(plt, "fractal_$(num_points)_dinh.png")
            println("✅ Đã lưu ảnh vào fractal_$(num_points)_dinh.png")
        catch e
            println("Lỗi khi lưu ảnh: ", e)
        end
        draw_time = time() - draw_start_time
        println("Thời gian vẽ và lưu hình: $(round(draw_time, digits=2)) giây")

        # Thời gian tổng
        total_time = time() - total_start_time
        println("Tổng thời gian thực thi: $(round(total_time, digits=2)) giây")

    catch e
        if isa(e, ErrorException)
            println("Lỗi: ", e.msg)
        else
            println("Đã xảy ra lỗi không xác định: ", e)
        end
    end
end

# Chạy chương trình
main()