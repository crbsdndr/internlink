<?php

namespace App\Http\Controllers;

use App\Models\School;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class SchoolController extends Controller
{
    private const SEARCH_COLUMNS = ['name', 'address', 'phone', 'email'];

    public function index(Request $request)
    {
        $query = DB::table('school_details_view')
            ->select('id', 'code', 'name', 'address', 'phone', 'email', 'website', 'created_at', 'updated_at');

        $filters = [];

        $name = trim((string) $request->query('name', ''));
        if ($name !== '') {
            $query->whereRaw('LOWER(name) LIKE ?', ['%' . strtolower($name) . '%']);
            $filters[] = [
                'param' => 'name',
                'label' => 'Name: ' . $name,
            ];
        }

        $email = trim((string) $request->query('email', ''));
        if ($email !== '') {
            $query->whereRaw('LOWER(email) LIKE ?', ['%' . strtolower($email) . '%']);
            $filters[] = [
                'param' => 'email',
                'label' => 'Email: ' . $email,
            ];
        }

        $phone = trim((string) $request->query('phone', ''));
        if ($phone !== '') {
            $query->whereRaw("LOWER(phone) LIKE ?", ['%' . strtolower($phone) . '%']);
            $filters[] = [
                'param' => 'phone',
                'label' => 'Phone: ' . $phone,
            ];
        }

        $hasWebsite = $request->query('has_website');
        if (in_array($hasWebsite, ['true', 'false'], true)) {
            if ($hasWebsite === 'true') {
                $query->whereNotNull('website')->whereRaw("TRIM(website) <> ''");
            } else {
                $query->where(function ($sub) {
                    $sub->whereNull('website')
                        ->orWhereRaw("TRIM(COALESCE(website, '')) = ''");
                });
            }
            $filters[] = [
                'param' => 'has_website',
                'label' => 'Has Website?: ' . ucfirst($hasWebsite),
            ];
        }

        if ($q = trim((string) $request->query('q', ''))) {
            $query->where(function ($sub) use ($q) {
                $lower = strtolower($q);
                foreach (self::SEARCH_COLUMNS as $column) {
                    $sub->orWhereRaw('LOWER(' . $column . ") LIKE ?", ['%' . $lower . '%']);
                }
            });
        }

        $sort = $request->query('sort', 'created_at:desc');
        [$sortField, $sortDir] = array_pad(explode(':', $sort, 2), 2, 'desc');
        $allowedSorts = [
            'name' => 'name',
            'email' => 'email',
            'created_at' => 'created_at',
            'updated_at' => 'updated_at',
        ];

        $column = $allowedSorts[$sortField] ?? 'created_at';
        $direction = strtolower($sortDir) === 'asc' ? 'asc' : 'desc';

        $schools = $query
            ->orderBy($column, $direction)
            ->paginate(10)
            ->withQueryString();

        return view('school.index', [
            'schools' => $schools,
            'filters' => $filters,
            'sort' => $column . ':' . $direction,
        ]);
    }

    public function create()
    {
        return view('school.create');
    }

    public function store(Request $request)
    {
        $data = $this->validateSchool($request);

        $school = School::create($data);

        return redirect('/schools/' . $school->id . '/read')->with('status', 'School created successfully.');
    }

    public function show(int $id)
    {
        $school = DB::table('school_details_view')->where('id', $id)->first();
        abort_if(!$school, 404);

        return view('school.show', compact('school'));
    }

    public function edit($id)
    {
        $school = School::findOrFail($id);

        return view('school.edit', compact('school'));
    }

    public function update(Request $request, $id)
    {
        $school = School::findOrFail($id);
        $data = $this->validateSchool($request, $school->id);

        $school->fill($data);
        $school->save();

        return redirect('/schools/' . $school->id . '/read')->with('status', 'School updated successfully.');
    }

    public function destroy($id)
    {
        $school = School::findOrFail($id);
        $school->delete();

        return redirect('/schools')->with('status', 'School deleted successfully.');
    }

    private function validateSchool(Request $request, ?int $schoolId = null): array
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:150'],
            'address' => ['required', 'string', 'max:1000'],
            'city' => ['nullable', 'string', 'max:100'],
            'postal_code' => ['nullable', 'string', 'max:20'],
            'phone' => [
                'required',
                'string',
                'max:30',
                'regex:/^[0-9+().\\-\\s]{7,30}$/',
                Rule::unique('schools', 'phone')->ignore($schoolId),
            ],
            'email' => ['required', 'email', 'max:255', Rule::unique('schools', 'email')->ignore($schoolId)],
            'website' => ['nullable', 'url', 'max:255'],
            'principal_name' => ['nullable', 'string', 'max:150'],
            'principal_nip' => ['nullable', 'string', 'max:50'],
        ]);

        $validated['name'] = trim($validated['name']);
        $validated['address'] = trim($validated['address']);
        $validated['city'] = isset($validated['city']) ? trim($validated['city']) : null;
        $validated['postal_code'] = isset($validated['postal_code']) ? trim($validated['postal_code']) : null;
        $validated['phone'] = preg_replace('/\s+/', ' ', trim($validated['phone']));
        $validated['email'] = strtolower(trim($validated['email']));
        $validated['website'] = isset($validated['website']) && $validated['website'] !== ''
            ? Str::of($validated['website'])->trim()->toString()
            : null;
        $validated['principal_name'] = isset($validated['principal_name']) ? trim($validated['principal_name']) : null;
        $validated['principal_nip'] = isset($validated['principal_nip']) ? trim($validated['principal_nip']) : null;

        return $validated;
    }
}
